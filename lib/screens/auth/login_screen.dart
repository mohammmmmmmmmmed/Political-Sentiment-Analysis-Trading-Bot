import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/colors.dart';
import '../../constants/text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  late AnimationController _mainController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _shakeAnimation;

  // Background particles state
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Configure status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Initialize animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Fade in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.1, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Slide up animation
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Shake animation
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: ShakeCurve()))
        .animate(_mainController);
    
    // Start animations
    _mainController.forward();
    
    // Initialize background particles
    _initParticles();
  }

  void _initParticles() {
    // Create 30 floating particles for the background
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        position: Offset(
          _random.nextDouble() * 400,
          _random.nextDouble() * 800,
        ),
        size: _random.nextDouble() * 10 + 2,
        speed: _random.nextDouble() * 0.5 + 0.1,
        angle: _random.nextDouble() * pi * 2,
        opacity: _random.nextDouble() * 0.4 + 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        // Simulating API call
        await Future.delayed(const Duration(seconds: 2));

        if (_emailController.text == "test@test.com" && _passwordController.text == "wrongpass") {
          _showError("Invalid credentials");
          
          // Create shake effect
          _mainController.reset();
          _mainController.forward(from: 0.7);
        } else {
          _showSuccess();
          
          // Add delay before navigation
          await Future.delayed(const Duration(milliseconds: 800));
          
          // Navigate with fade transition
          Navigator.of(context).pushReplacementNamed(
            '/dashboard',
            arguments: {'email': _emailController.text},
          );
        }
      } catch (e) {
        _showError("An error occurred. Please try again.");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _handleQuickLogin() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showError(String message) {
    // Vibrate device for error feedback
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    );
  }

  void _showSuccess() {
    // Light haptic feedback for success
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text("Login successful!"),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _mainController,
        builder: (context, _) {
          // Update particle positions
          for (var particle in _particles) {
            particle.update();
          }
          
          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4A55A2), // Match splash screen color
                      Color(0xFF3D4785), // Darker variant
                    ],
                  ),
                ),
              ),
              
              // Particles background
              if (!isKeyboardVisible)
                CustomPaint(
                  painter: ParticlePainter(_particles),
                  size: Size(screenSize.width, screenSize.height),
                ),
              
              // Wave animation at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: WaveAnimation(
                  baseColor: Colors.white,
                ),
              ),
              
              // Login form
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: Opacity(
                        opacity: _fadeInAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: _buildLoginCard(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // App title and logo at top (visible when keyboard is hidden)
              if (!isKeyboardVisible)
                Positioned(
                  top: screenSize.height * 0.08,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _fadeInAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value * 0.5),
                      child: Column(
                        children: [
                          Icon(
                            Icons.analytics_sharp,
                            size: 60,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Trading Bot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Smart Trading, Simplified',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome text
            Text(
              'Welcome Back!',
              style: AppTextStyles.headerLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A55A2),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Sign in to access your trading dashboard',
              style: AppTextStyles.bodyRegular.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Email field with animated focus effect
            CustomTextField(
              hint: 'Email Address',
              controller: _emailController,
              prefixIcon: Icons.email,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 16),

            // Password field with animated focus effect
            CustomTextField(
              hint: 'Password',
              controller: _passwordController,
              isPassword: true,
              prefixIcon: Icons.lock,
              validator: _validatePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            // Remember me and forgot password row
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() => _rememberMe = value ?? false),
                          activeColor: Color(0xFF4A55A2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF4A55A2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Login button with loading state
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 52,
              child: CustomButton(
                text: _isLoading ? '' : 'Log In',
                onPressed: _isLoading ? null : _handleLogin,
                backgroundColor: Color(0xFF4A55A2),
                // child: _isLoading
                //     ? LoadingIndicator()
                //     : null,
              ),
            ),
            SizedBox(height: 16),

            // Quick login button
            CustomButton(
              text: 'Quick Login',
              onPressed: _handleQuickLogin,
              backgroundColor: const Color.fromARGB(255, 240, 6, 6),
            ),
            SizedBox(height: 16),

            // Divider with "or"
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('or', style: AppTextStyles.bodyRegular.copyWith(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            SizedBox(height: 16),

            // Social login buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: Icons.g_mobiledata,
                  color: Colors.red,
                  onTap: () {},
                ),
                SizedBox(width: 16),
                _buildSocialButton(
                  icon: Icons.facebook,
                  color: Colors.blue,
                  onTap: () {},
                ),
                SizedBox(width: 16),
                _buildSocialButton(
                  icon: Icons.apple,
                  color: Colors.black,
                  onTap: () {},
                ),
              ],
            ),
            SizedBox(height: 24),

            // Sign up link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ", style: AppTextStyles.bodyRegular),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signup');
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF4A55A2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

// Enhanced loading indicator with animated dots
class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(_controller.value, 0),
            SizedBox(width: 6),
            _buildDot(_controller.value, 0.2),
            SizedBox(width: 6),
            _buildDot(_controller.value, 0.4),
          ],
        );
      },
    );
  }

  Widget _buildDot(double animationValue, double delay) {
    final double scaleValue = sin((animationValue * 2 * pi - delay) % (2 * pi)) * 0.3 + 0.7;
    
    return Transform.scale(
      scale: scaleValue,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ShakeCurve extends Curve {
  @override
  double transform(double t) {
    return sin(t * pi * 5);
  }
}

// Enhanced wave animation
class WaveAnimation extends StatefulWidget {
  final Color baseColor;

  const WaveAnimation({
    Key? key,
    required this.baseColor,
  }) : super(key: key);

  @override
  _WaveAnimationState createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(seconds: 3 + index),
        vsync: this,
      )..repeat();
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 2 * pi).animate(controller)
        ..addListener(() {
          setState(() {});
        });
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: WavePainter(
            wavePhase: _animations[0].value,
            waveColor: widget.baseColor.withOpacity(0.3),
            amplitude: 15,
            frequency: 1.5,
          ),
          size: Size(double.infinity, 200),
        ),
        CustomPaint(
          painter: WavePainter(
            wavePhase: _animations[1].value,
            waveColor: widget.baseColor.withOpacity(0.5),
            amplitude: 20,
            frequency: 1.2,
          ),
          size: Size(double.infinity, 200),
        ),
        CustomPaint(
          painter: WavePainter(
            wavePhase: _animations[2].value,
            waveColor: widget.baseColor,
            amplitude: 25,
            frequency: 1.0,
          ),
          size: Size(double.infinity, 200),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double wavePhase;
  final Color waveColor;
  final double amplitude;
  final double frequency;

  WavePainter({
    required this.wavePhase,
    required this.waveColor,
    required this.amplitude,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width + 10; x++) {
      final y = size.height * 0.8 +
          (amplitude * sin((frequency * 2 * pi * x / size.width) + wavePhase));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Particle system for background animation
class Particle {
  Offset position;
  double size;
  double speed;
  double angle;
  double opacity;
  
  Particle({
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
    required this.opacity,
  });
  
  void update() {
    position = Offset(
      position.dx + cos(angle) * speed,
      position.dy + sin(angle) * speed,
    );
    
    // Reset particle position if it goes off screen
    if (position.dx < -50 || position.dx > 450 || 
        position.dy < -50 || position.dy > 850) {
      position = Offset(
        Random().nextDouble() * 400,
        Random().nextDouble() * 800,
      );
      angle = Random().nextDouble() * pi * 2;
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlePainter(this.particles);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}