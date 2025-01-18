#include <iostream>
#include <curl/curl.h>
#include <libxml2/libxml/HTMLparser.h>
#include <libxml2/libxml/xpath.h>
#include <vector>
#include <fstream>
#include <ctime>
#include <sstream>
#include <string>
#include <map>
#include <regex>
#include <filesystem>
#include <iomanip>

#ifdef _WIN32
#include <windows.h>
#elif __APPLE__
#include <cstdlib>
#elif __linux__
#include <cstdlib>
#endif

namespace fs = std::filesystem;

// Structure to store site information
struct Site {
    std::string url;
    std::string name;
};

// Helper function to get current timestamp
std::string get_timestamp() {
    auto now = std::time(nullptr);
    auto* tm = std::localtime(&now);
    char buffer[32];
    std::strftime(buffer, sizeof(buffer), "%Y/%m/%d/%H", tm);
    return std::string(buffer);
}

// Helper function to extract domain name from URL
std::string get_site_name(const std::string& url) {
    std::regex domain_regex("^(?:https?://)?(?:www\\.)?([^/]+)");
    std::smatch matches;
    if (std::regex_search(url, matches, domain_regex)) {
        return matches[1].str();
    }
    return "unknown_site";
}

// Function to validate and correct Reddit URLs
std::string validate_reddit_url(const std::string& url) {
    std::string corrected_url = url;
    
    // Add https:// if missing
    if (url.find("http://") == std::string::npos && url.find("https://") == std::string::npos) {
        corrected_url = "https://" + url;
    }
    
    // Convert www.reddit.com to old.reddit.com
    std::regex reddit_regex("(https?://)(www\\.)?reddit\\.com");
    corrected_url = std::regex_replace(corrected_url, reddit_regex, "$1old.reddit.com");
    
    return corrected_url;
}

// Function to check if URL is a subreddit landing page
bool is_subreddit_landing(const std::string& url) {
    std::regex subreddit_regex("https?://old\\.reddit\\.com/r/[^/]+/?$");
    return std::regex_match(url, subreddit_regex);
}

// Function to check if URL is a post
bool is_post(const std::string& url) {
    std::regex post_regex("https?://old\\.reddit\\.com/r/[^/]+/comments/[^/]+/[^/]+/?");
    return std::regex_match(url, post_regex);
}

// Function to extract subreddit name from URL
std::string extract_subreddit_name(const std::string& url) {
    std::regex subreddit_regex("https?://old\\.reddit\\.com/r/([^/]+)");
    std::smatch matches;
    if (std::regex_search(url, matches, subreddit_regex)) {
        return matches[1].str();
    }
    return "";
}

size_t WriteCallback(void *contents, size_t size, size_t nmemb, std::string *userp) {
    try {
        userp->append((char*)contents, size * nmemb);
        return size * nmemb;
    } catch(const std::bad_alloc &e) {
        return 0;
    }
}

std::string get_request(const std::string& url) {
    CURL *curl = curl_easy_init();
    std::string result;
    
    if (!curl) {
        std::cerr << "Failed to initialize CURL" << std::endl;
        return result;
    }
    
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &result);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
    
    CURLcode res = curl_easy_perform(curl);
    
    if(res != CURLE_OK) {
        std::cerr << "curl_easy_perform() failed for " << url << ": " << curl_easy_strerror(res) << std::endl;
        curl_easy_cleanup(curl);
        return result;
    }
    
    long http_code = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_code);
    if(http_code != 200) {
        std::cerr << "HTTP request failed for " << url << " with code: " << http_code << std::endl;
        curl_easy_cleanup(curl);
        return result;
    }
    
    std::cout << "Successfully fetched " << result.length() << " bytes from " << url << std::endl;
    
    curl_easy_cleanup(curl);
    return result;
}

bool save_content(const std::string& content, const std::string& url, const std::string& base_folder) {
    std::string site_name = get_site_name(url);
    std::string subreddit = extract_subreddit_name(url); // Extract subreddit name
    std::string timestamp = get_timestamp();
    fs::path folder_path = fs::path(base_folder) / timestamp;
    fs::create_directories(folder_path);

    // Include subreddit name in the file name
    std::string filename = (folder_path / (subreddit + "_" + site_name + "_" + std::to_string(std::time(nullptr)) + ".html")).string();
    
    try {
        std::ofstream outfile(filename);
        if (!outfile.is_open()) {
            std::cerr << "Failed to open file: " << filename << std::endl;
            return false;
        }
        
        outfile << content;
        outfile.close();
        
        std::cout << "Content saved to: " << filename << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Error saving file: " << e.what() << std::endl;
        return false;
    }
}

void display_sites(const std::vector<std::string>& sites) {
    std::cout << "Current sites:\n";
    for (size_t i = 0; i < sites.size(); ++i) {
        std::cout << i + 1 << ". " << sites[i] << "\n";
    }
}

void add_site(std::vector<std::string>& sites) {
    std::string new_site;
    std::cout << "Enter the URL of the site to add: ";
    std::cin >> new_site;
    sites.push_back(new_site);
    std::cout << "Site added.\n";
}

void edit_site(std::vector<std::string>& sites) {
    display_sites(sites);
    size_t index;
    std::cout << "Enter the number of the site to edit: ";
    std::cin >> index;
    if (index > 0 && index <= sites.size()) {
        std::string new_url;
        std::cout << "Enter the new URL: ";
        std::cin >> new_url;
        sites[index - 1] = new_url;
        std::cout << "Site updated.\n";
    } else {
        std::cerr << "Invalid selection.\n";
    }
}

void delete_site(std::vector<std::string>& sites) {
    display_sites(sites);
    size_t index;
    std::cout << "Enter the number of the site to delete: ";
    std::cin >> index;
    if (index > 0 && index <= sites.size()) {
        sites.erase(sites.begin() + index - 1);
        std::cout << "Site deleted.\n";
    } else {
        std::cerr << "Invalid selection.\n";
    }
}

void open_in_browser(const std::string& file_path) {
#ifdef _WIN32
    ShellExecute(nullptr, "open", file_path.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
#elif __APPLE__
    std::string command = "open " + file_path;
    system(command.c_str());
#elif __linux__
    std::string command = "xdg-open " + file_path;
    system(command.c_str());
#else
    std::cerr << "Unsupported platform. Cannot open file in browser.\n";
#endif
}

void display_scraped_files(const std::string& base_folder) {
    std::vector<std::string> files;
    std::cout << "Scraped HTML files:\n";
    try {
        for (const auto& entry : fs::recursive_directory_iterator(base_folder)) {
            if (entry.is_regular_file() && entry.path().extension() == ".html") {
                files.push_back(entry.path().string());
                std::cout << files.size() << ". " << entry.path().string() << "\n";
            }
        }

        if (!files.empty()) {
            std::cout << "Enter the number of the file to open in the browser (0 to cancel): ";
            size_t choice;
            std::cin >> choice;
            if (choice > 0 && choice <= files.size()) {
                open_in_browser(files[choice - 1]);
            } else if (choice != 0) {
                std::cerr << "Invalid selection.\n";
            }
        } else {
            std::cout << "No scraped HTML files found.\n";
        }
    } catch (const std::exception& e) {
        std::cerr << "Error reading directory: " << e.what() << "\n";
    }
}

void delete_all_files(const std::string& base_folder) {
    try {
        if (fs::exists(base_folder)) {
            fs::remove_all(base_folder);
            std::cout << "All files in " << base_folder << " have been deleted.\n";
        } else {
            std::cout << "Folder " << base_folder << " does not exist.\n";
        }
    } catch (const std::exception& e) {
        std::cerr << "Error deleting files: " << e.what() << "\n";
    }
}

std::vector<std::string> extract_links_from_html(const std::string& html_content) {
    std::vector<std::string> links;
    xmlDocPtr doc = htmlReadDoc((const xmlChar*)html_content.c_str(), nullptr, nullptr, HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING);
    if (!doc) {
        std::cerr << "Failed to parse HTML document." << std::endl;
        return links;
    }

    xmlXPathContextPtr context = xmlXPathNewContext(doc);
    if (!context) {
        std::cerr << "Failed to create XPath context." << std::endl;
        xmlFreeDoc(doc);
        return links;
    }

    xmlXPathObjectPtr result = xmlXPathEvalExpression((const xmlChar*)"//a/@href", context);
    if (!result) {
        std::cerr << "Failed to evaluate XPath expression." << std::endl;
        xmlXPathFreeContext(context);
        xmlFreeDoc(doc);
        return links;
    }

    xmlNodeSetPtr nodeset = result->nodesetval;
    if (nodeset) {
        for (int i = 0; i < nodeset->nodeNr; ++i) {
            xmlNodePtr node = nodeset->nodeTab[i];
            xmlChar* href = xmlNodeGetContent(node);
            if (href) {
                links.push_back(std::string((char*)href));
                xmlFree(href);
            }
        }
    }

    xmlXPathFreeObject(result);
    xmlXPathFreeContext(context);
    xmlFreeDoc(doc);

    return links;
}

std::vector<std::string> filter_post_links(const std::vector<std::string>& links, const std::string& subreddit) {
    std::vector<std::string> post_links;
    std::regex post_regex("https?://(?:www\\.)?old\\.reddit\\.com/r/" + subreddit + "/comments/[^/]+/[^/]+/?");

    for (const auto& link : links) {
        if (std::regex_match(link, post_regex)) {
            post_links.push_back(link);
        }
    }

    return post_links;
}

void save_links_to_csv(const std::vector<std::string>& links, const std::string& csv_file_path) {
    std::ofstream csv_file(csv_file_path);
    if (!csv_file.is_open()) {
        std::cerr << "Failed to open CSV file for writing: " << csv_file_path << std::endl;
        return;
    }

    csv_file << "Link\n";  // Header
    for (const auto& link : links) {
        csv_file << link << "\n";
    }

    csv_file.close();
    std::cout << "Links saved to: " << csv_file_path << std::endl;
}

// Function to extract subreddit name from file name
std::string extract_subreddit_name_from_filename(const std::string& filename) {
    std::regex subreddit_regex("([^/_]+)_old\\.reddit\\.com_.+\\.html");
    std::smatch matches;
    if (std::regex_search(filename, matches, subreddit_regex)) {
        return matches[1].str();
    }
    return "";
}

void extract_comments_from_html(const std::string& html_content, const std::string& csv_file_path) {
    // Regex to capture everything inside <div class="md">
    std::regex comment_regex(R"(<div class="md">([\s\S]*?)<\/div>)");
    std::smatch matches;

    std::vector<std::string> comments;
    std::string::const_iterator search_start(html_content.cbegin());

    // Find all matches
    while (std::regex_search(search_start, html_content.cend(), matches, comment_regex)) {
        std::string content = matches[1].str();

        // Remove HTML tags from the content
        std::regex tag_regex(R"(<[^>]*>)");
        std::string text_content = std::regex_replace(content, tag_regex, "");

        // Trim leading/trailing whitespace
        text_content.erase(0, text_content.find_first_not_of(" \t\n\r\f\v"));
        text_content.erase(text_content.find_last_not_of(" \t\n\r\f\v") + 1);

        if (!text_content.empty()) {
            comments.push_back(text_content);
        }

        search_start = matches.suffix().first;
    }

    // Save comments to CSV
    if (!comments.empty()) {
        std::ofstream csv_file(csv_file_path);
        if (!csv_file.is_open()) {
            std::cerr << "Failed to open CSV file for writing: " << csv_file_path << std::endl;
            return;
        }

        csv_file << "Comment\n";  // Header
        for (const auto& comment : comments) {
            // Escape quotes and wrap in quotes for proper CSV formatting
            std::string escaped_comment = comment;
            size_t pos = 0;
            while ((pos = escaped_comment.find('"', pos)) != std::string::npos) {
                escaped_comment.replace(pos, 1, "\"\"");
                pos += 2;
            }
            csv_file << "\"" << escaped_comment << "\"\n";
        }

        csv_file.close();
        std::cout << "Comments saved to: " << csv_file_path << std::endl;
    } else {
        std::cout << "No comments found in the selected file.\n";
    }
}
void extract_links_from_scraped_file(const std::string& base_folder, const std::string& csv_folder) {
    if (!fs::exists(base_folder)) {
        std::cerr << "Folder " << base_folder << " does not exist. Creating it now.\n";
        fs::create_directories(base_folder);
    }

    if (!fs::exists(csv_folder)) {
        std::cerr << "Folder " << csv_folder << " does not exist. Creating it now.\n";
        fs::create_directories(csv_folder);
    }

    std::vector<std::string> files;
    std::cout << "Scraped HTML files:\n";
    try {
        for (const auto& entry : fs::recursive_directory_iterator(base_folder)) {
            if (entry.is_regular_file() && entry.path().extension() == ".html") {
                files.push_back(entry.path().string());
                std::cout << files.size() << ". " << entry.path().string() << "\n";
            }
        }

        if (!files.empty()) {
            std::cout << "Enter the number of the file to extract links from (0 to cancel): ";
            size_t choice;
            std::cin >> choice;
            if (choice > 0 && choice <= files.size()) {
                std::ifstream html_file(files[choice - 1]);
                if (!html_file.is_open()) {
                    std::cerr << "Failed to open HTML file: " << files[choice - 1] << std::endl;
                    return;
                }

                std::string html_content((std::istreambuf_iterator<char>(html_file)), std::istreambuf_iterator<char>());
                html_file.close();

                std::vector<std::string> links = extract_links_from_html(html_content);
                if (!links.empty()) {
                    // Extract subreddit name from the file name
                    std::string subreddit = extract_subreddit_name_from_filename(files[choice - 1]);
                    if (!subreddit.empty()) {
                        std::vector<std::string> post_links = filter_post_links(links, subreddit);
                        
                        if (!post_links.empty()) {
                            std::string csv_file_path = (fs::path(csv_folder) / fs::path(files[choice - 1]).stem()).string() + "_post_links.csv";
                            save_links_to_csv(post_links, csv_file_path);
                        } else {
                            std::cout << "No post links found in the selected file.\n";
                        }
                    } else {
                        std::cout << "Could not determine subreddit from the file name.\n";
                    }
                } else {
                    std::cout << "No links found in the selected file.\n";
                }
            } else if (choice != 0) {
                std::cerr << "Invalid selection.\n";
            }
        } else {
            std::cout << "No scraped HTML files found.\n";
        }
    } catch (const std::exception& e) {
        std::cerr << "Error reading directory: " << e.what() << "\n";
    }
}

void scrape_links(const std::string& base_folder, const std::string& csv_folder) {
    std::cout << "Choose an option:\n";
    std::cout << "1. Scrape links from a subreddit\n";
    std::cout << "2. Scrape comments from a post\n";
    std::cout << "Choose an option: ";
    int choice;
    std::cin >> choice;

    if (choice == 1) {
        extract_links_from_scraped_file(base_folder, csv_folder);
    } else if (choice == 2) {
        if (!fs::exists(base_folder)) {
            std::cerr << "Folder " << base_folder << " does not exist. Creating it now.\n";
            fs::create_directories(base_folder);
        }

        if (!fs::exists(csv_folder)) {
            std::cerr << "Folder " << csv_folder << " does not exist. Creating it now.\n";
            fs::create_directories(csv_folder);
        }

        std::vector<std::string> files;
        std::cout << "Scraped HTML files:\n";
        try {
            for (const auto& entry : fs::recursive_directory_iterator(base_folder)) {
                if (entry.is_regular_file() && entry.path().extension() == ".html") {
                    files.push_back(entry.path().string());
                    std::cout << files.size() << ". " << entry.path().string() << "\n";
                }
            }

            if (!files.empty()) {
                std::cout << "Enter the number of the file to extract comments from (0 to cancel): ";
                size_t choice;
                std::cin >> choice;
                if (choice > 0 && choice <= files.size()) {
                    std::ifstream html_file(files[choice - 1]);
                    if (!html_file.is_open()) {
                        std::cerr << "Failed to open HTML file: " << files[choice - 1] << std::endl;
                        return;
                    }

                    std::string html_content((std::istreambuf_iterator<char>(html_file)), std::istreambuf_iterator<char>());
                    html_file.close();

                    std::string csv_file_path = (fs::path(csv_folder) / fs::path(files[choice - 1]).stem()).string() + "_comments.csv";
                    extract_comments_from_html(html_content, csv_file_path);
                } else if (choice != 0) {
                    std::cerr << "Invalid selection.\n";
                }
            } else {
                std::cout << "No scraped HTML files found.\n";
            }
        } catch (const std::exception& e) {
            std::cerr << "Error reading directory: " << e.what() << "\n";
        }
    } else {
        std::cerr << "Invalid option. Please try again.\n";
    }
}

int main() {
    std::vector<std::string> sites = {
        "https://old.reddit.com/r/wallstreetbets/",
    };
    
    std::string base_folder = "html_docs";
    std::string csv_folder = "csv_docs";

    if (!fs::exists(base_folder)) {
        std::cerr << "Folder " << base_folder << " does not exist. Creating it now.\n";
        fs::create_directories(base_folder);
    }

    if (!fs::exists(csv_folder)) {
        std::cerr << "Folder " << csv_folder << " does not exist. Creating it now.\n";
        fs::create_directories(csv_folder);
    }

    while (true) {
        std::cout << "\nOptions:\n";
        std::cout << "1. Process sites\n";
        std::cout << "2. Add a site\n";
        std::cout << "3. Edit a site\n";
        std::cout << "4. Delete a site\n";
        std::cout << "5. Display and open scraped HTML files\n";
        std::cout << "6. Delete all scraped files\n";
        std::cout << "7. Scrape links\n";
        std::cout << "8. Exit\n";
        std::cout << "Choose an option: ";
        int choice;
        std::cin >> choice;

        if (choice == 1) {
            try {
                std::cout << "Initializing CURL..." << std::endl;
                curl_global_init(CURL_GLOBAL_ALL);
                
                for (const auto& site : sites) {
                    std::string validated_url = validate_reddit_url(site);
                    if (!is_subreddit_landing(validated_url) && !is_post(validated_url)) {
                        std::cerr << "URL is not a subreddit landing page or a post: " << validated_url << std::endl;
                        continue;
                    }
                    
                    std::cout << "\nProcessing " << validated_url << "..." << std::endl;
                    
                    std::string html_content = get_request(validated_url);
                    if(html_content.empty()) {
                        std::cerr << "Failed to fetch content from " << validated_url << std::endl;
                        continue;
                    }
                    
                    if (!save_content(html_content, validated_url, base_folder)) {
                        std::cerr << "Failed to save content from " << validated_url << std::endl;
                        continue;
                    }
                }
                
                curl_global_cleanup();
                std::cout << "\nAll sites processed." << std::endl;
                
            } catch (const std::exception& e) {
                std::cerr << "Exception caught: " << e.what() << std::endl;
                curl_global_cleanup();
            }
        } else if (choice == 2) {
            add_site(sites);
        } else if (choice == 3) {
            edit_site(sites);
        } else if (choice == 4) {
            delete_site(sites);
        } else if (choice == 5) {
            display_scraped_files(base_folder);
        } else if (choice == 6) {
            delete_all_files(base_folder);
        } else if (choice == 7) {
            scrape_links(base_folder, csv_folder);
        } else if (choice == 8) {
            break;
        } else {
            std::cerr << "Invalid option. Please try again.\n";
        }
    }
    
    return 0;
}