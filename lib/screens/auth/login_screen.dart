import 'dart:math';
import 'package:flutter/material.dart';
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
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: ShakeCurve()))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
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
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await Future.delayed(const Duration(seconds: 2));

        if (_emailController.text == "test@test.com" && _passwordController.text == "wrongpass") {
          _showError("Invalid credentials");
          _shakeController.forward().then((_) => _shakeController.reset());
        } else {
          _showSuccess();
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } catch (e) {
        _showError("An error occurred");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleQuickLogin() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text("Login successful!"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6C5CE7),
                    Color(0xFF6C5CE7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: WaveAnimation(
                baseColor: Colors.white,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TweenAnimationBuilder(
                              duration: Duration(seconds: 1),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF6C5CE7),
                                        Color(0xFF6C5CE7),
                                      ],
                                    ),
                                  ),
                                  child: Icon(Icons.person, size: 40, color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            TweenAnimationBuilder(
                              duration: Duration(milliseconds: 800),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: child,
                                );
                              },
                              child: Column(
                                children: [
                                  Text(
                                    'Welcome Back!',
                                    style: AppTextStyles.headerLarge.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Sign in to continue',
                                    style: AppTextStyles.bodyRegular.copyWith(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 32),
                            CustomTextField(
                              hint: 'Email Address',
                              controller: _emailController,
                              prefixIcon: Icons.email,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            SizedBox(height: 16),
                            CustomTextField(
                              hint: 'Password',
                              controller: _passwordController,
                              isPassword: true,
                              prefixIcon: Icons.lock,
                              validator: _validatePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                            ),
                            SizedBox(height: 24),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              height: 50,
                              child: CustomButton(
                                text: _isLoading ? 'Logging in...' : 'Log In',
                                onPressed: _isLoading ? null : _handleLogin,
                                backgroundColor: Color.fromRGBO(108, 92, 231, 1),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(height: 16),
                            CustomButton(
                              text: 'Quick Login',
                              onPressed: _handleQuickLogin,
                              backgroundColor: const Color.fromARGB(255, 240, 6, 6),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('or', style: AppTextStyles.bodyRegular.copyWith(color: Colors.grey)),
                                ),
                                Expanded(child: Divider(color: Colors.grey)),
                              ],
                            ),
                            SizedBox(height: 16),
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
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            waveColor: widget.baseColor.withOpacity(0.1),
            amplitude: 15,
            frequency: 1.5,
          ),
          size: Size(double.infinity, 200),
        ),
        CustomPaint(
          painter: WavePainter(
            wavePhase: _animations[1].value,
            waveColor: widget.baseColor.withOpacity(0.2),
            amplitude: 20,
            frequency: 1.2,
          ),
          size: Size(double.infinity, 200),
        ),
        CustomPaint(
          painter: WavePainter(
            wavePhase: _animations[2].value,
            waveColor: widget.baseColor.withOpacity(0.3),
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