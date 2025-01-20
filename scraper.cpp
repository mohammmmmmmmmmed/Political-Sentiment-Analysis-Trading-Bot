#include <iostream>
#include <curl/curl.h>
#include <vector>
#include <fstream>
#include <ctime>
#include <string>
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

// Helper function to get current timestamp in DD-MM-YY-Hr-Min format
std::string get_timestamp() {
    auto now = std::time(nullptr);
    auto* tm = std::localtime(&now);
    char buffer[32];
    std::strftime(buffer, sizeof(buffer), "%d-%m-%y-%H-%M", tm);
    return std::string(buffer);
}

// Function to validate and correct Reddit URLs
std::string validate_reddit_url(const std::string& url) {
    std::string corrected_url = url;

    // Check if the URL is a Reddit URL
    std::regex reddit_regex("^(https?://)?(www\\.)?reddit\\.com");
    if (std::regex_search(url, reddit_regex)) {
        // Add https:// if missing
        if (url.find("http://") == std::string::npos && url.find("https://") == std::string::npos) {
            corrected_url = "https://" + url;
        }

        // Convert www.reddit.com to old.reddit.com
        corrected_url = std::regex_replace(corrected_url, reddit_regex, "$1old.reddit.com");
    }

    return corrected_url;
}

// Function to check if URL is a subreddit landing page
bool is_subreddit_landing(const std::string& url) {
    std::regex subreddit_regex("https?://(?:www\\.)?(?:old\\.)?reddit\\.com/r/[^/]+/?$");
    return std::regex_match(url, subreddit_regex);
}

// Function to check if URL is a post
bool is_post(const std::string& url) {
    std::regex post_regex("https?://(?:www\\.)?(?:old\\.)?reddit\\.com/r/[^/]+/comments/[^/]+/[^/]+/?");
    return std::regex_match(url, post_regex);
}

// Function to extract subreddit name from URL
std::string extract_subreddit_name(const std::string& url) {
    std::regex subreddit_regex("https?://(?:www\\.)?(?:old\\.)?reddit\\.com/r/([^/]+)");
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

bool save_content(const std::string& content, const std::string& filename) {
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

void display_scraped_files(const std::string& folder) {
    std::vector<std::string> files;
    std::cout << "Scraped files:\n";
    try {
        for (const auto& entry : fs::directory_iterator(folder)) {
            if (entry.is_regular_file()) {
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
            std::cout << "No scraped files found.\n";
        }
    } catch (const std::exception& e) {
        std::cerr << "Error reading directory: " << e.what() << "\n";
    }
}

void delete_all_files(const std::string& folder) {
    try {
        if (fs::exists(folder)) {
            fs::remove_all(folder);
            std::cout << "All files in " << folder << " have been deleted.\n";
        } else {
            std::cout << "Folder " << folder << " does not exist.\n";
        }
    } catch (const std::exception& e) {
        std::cerr << "Error deleting files: " << e.what() << "\n";
    }
}

// Function to scrape links from subreddit HTML
std::vector<std::string> scrape_links_from_html(const std::string& html_content) {
    std::vector<std::string> links;
    std::regex link_regex("<a\\s+(?:[^>]*?\\s+)?href=\"([^\"]*)\"[^>]*>");
    std::smatch matches;

    std::string::const_iterator search_start(html_content.cbegin());
    while (std::regex_search(search_start, html_content.cend(), matches, link_regex)) {
        std::string link = matches[1].str();
        if (!link.empty()) {
            links.push_back(link);
        }
        search_start = matches.suffix().first;
    }

    return links;
}

// Function to scrape comments from post HTML
std::vector<std::string> scrape_comments_from_html(const std::string& html_content) {
    std::vector<std::string> comments;
    std::regex comment_regex("<div\\s+class=\"md\">([\\s\\S]*?)<\\/div>");
    std::smatch matches;

    std::string::const_iterator search_start(html_content.cbegin());
    while (std::regex_search(search_start, html_content.cend(), matches, comment_regex)) {
        std::string comment = matches[1].str();

        // Remove HTML tags from the comment
        std::regex tag_regex("<[^>]*>");
        std::string text_content = std::regex_replace(comment, tag_regex, "");

        // Trim leading/trailing whitespace
        text_content.erase(0, text_content.find_first_not_of(" \t\n\r\f\v"));
        text_content.erase(text_content.find_last_not_of(" \t\n\r\f\v") + 1);

        if (!text_content.empty()) {
            comments.push_back(text_content);
        }

        search_start = matches.suffix().first;
    }

    return comments;
}

void process_reddit_url(const std::string& url, const std::string& html_folder, const std::string& csv_folder) {
    std::string validated_url = validate_reddit_url(url);
    std::string html_content = get_request(validated_url);

    if (html_content.empty()) {
        std::cerr << "Failed to fetch content from " << validated_url << std::endl;
        return;
    }

    std::string timestamp = get_timestamp();
    std::string subreddit_name = extract_subreddit_name(validated_url);
    std::string html_filename = (fs::path(html_folder) / (subreddit_name + "_" + timestamp + ".html")).string();

    if (!save_content(html_content, html_filename)) {
        std::cerr << "Failed to save content from " << validated_url << std::endl;
        return;
    }

    if (is_subreddit_landing(validated_url)) {
        std::vector<std::string> links = scrape_links_from_html(html_content);
        std::string csv_filename = (fs::path(csv_folder) / (subreddit_name + "_" + timestamp + "_links.csv")).string();
        
        std::ofstream csv_file(csv_filename);
        if (!csv_file.is_open()) {
            std::cerr << "Failed to open CSV file for writing: " << csv_filename << std::endl;
            return;
        }

        csv_file << "Link\n";  // Header
        for (const auto& link : links) {
            csv_file << link << "\n";
        }

        csv_file.close();
        std::cout << "Links saved to: " << csv_filename << std::endl;
    } else if (is_post(validated_url)) {
        std::vector<std::string> comments = scrape_comments_from_html(html_content);
        std::string csv_filename = (fs::path(csv_folder) / (subreddit_name + "_" + timestamp + "_comments.csv")).string();
        
        std::ofstream csv_file(csv_filename);
        if (!csv_file.is_open()) {
            std::cerr << "Failed to open CSV file for writing: " << csv_filename << std::endl;
            return;
        }

        csv_file << "Comment\n";  // Header
        for (const auto& comment : comments) {
            csv_file << "\"" << comment << "\"\n";
        }

        csv_file.close();
        std::cout << "Comments saved to: " << csv_filename << std::endl;
    }
}

int main() {
    std::vector<std::string> sites = {
        "https://old.reddit.com/r/wallstreetbets/",
        "https://old.reddit.com/r/programming/",
        "https://www.reddit.com/r/privacy/comments/1act8c5/nitter_is_dead/"
    };
    
    std::string html_folder = "html_docs";
    std::string csv_folder = "csv_docs";

    if (!fs::exists(html_folder)) {
        std::cerr << "Folder " << html_folder << " does not exist. Creating it now.\n";
        fs::create_directories(html_folder);
    }

    if (!fs::exists(csv_folder)) {
        std::cerr << "Folder " << csv_folder << " does not exist. Creating it now.\n";
        fs::create_directories(csv_folder);
    }

    while (true) {
        std::cout << "\nOptions:\n";
        std::cout << "1. Process Reddit links\n";
        std::cout << "2. Display and open scraped HTML files\n";
        std::cout << "3. Delete all scraped files\n";
        std::cout << "4. Exit\n";
        std::cout << "Choose an option: ";
        int choice;
        std::cin >> choice;

        if (choice == 1) {
            try {
                std::cout << "Initializing CURL..." << std::endl;
                curl_global_init(CURL_GLOBAL_ALL);
                
                for (const auto& site : sites) {
                    process_reddit_url(site, html_folder, csv_folder);
                }
                
                curl_global_cleanup();
                std::cout << "\nAll sites processed." << std::endl;
                
            } catch (const std::exception& e) {
                std::cerr << "Exception caught: " << e.what() << std::endl;
                curl_global_cleanup();
            }
        } else if (choice == 2) {
            display_scraped_files(html_folder);
        } else if (choice == 3) {
            delete_all_files(html_folder);
            delete_all_files(csv_folder);
        } else if (choice == 4) {
            break;
        } else {
            std::cerr << "Invalid option. Please try again.\n";
        }
    }
    
    return 0;
}