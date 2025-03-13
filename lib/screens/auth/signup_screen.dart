import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Function to validate email
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Function to validate password
  bool _validatePassword(String password) {
    return password.length >= 8; // Example: Password must be at least 8 characters
  }

  // Function to hash password (for demonstration, use a simple hash)
  String _hashPassword(String password) {
    return base64Encode(utf8.encode(password)); // Not secure, for demonstration only
  }

  // Function to handle sign-up
  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate inputs
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    if (!_validateEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email address')),
      );
      return;
    }

    if (!_validatePassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Hash the password
    final hashedPassword = _hashPassword(password);

    // Save user data locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('password', hashedPassword);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign-up successful!')),
    );

    // Navigate to the dashboard or login screen
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF7F7F7), // Light grey
                      Color.fromRGBO(108, 92, 231, 1), // Purple
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Create Account', style: AppTextStyles.headerLarge),
              const SizedBox(height: 8),
              const Text('Sign up to get started', style: AppTextStyles.bodyRegular),
              const SizedBox(height: 48),
              CustomTextField(
                hint: 'Full Name',
                controller: _nameController,
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hint: 'Email',
                controller: _emailController,
                prefixIcon: Icons.email,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hint: 'Password',
                controller: _passwordController,
                isPassword: true,
                prefixIcon: Icons.lock,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hint: 'Confirm Password',
                controller: _confirmPasswordController,
                isPassword: true,
                prefixIcon: Icons.lock,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Sign Up',
                backgroundColor: AppColors.primary,
                onPressed: _signUp,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: AppTextStyles.bodyRegular),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Sign In', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}