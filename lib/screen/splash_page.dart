import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  static const String _sessionLoggedInKey = 'session_logged_in';
  static const String _sessionUserNameKey = 'session_user_name';

  late final AnimationController _introController;
  late final AnimationController _ambientController;
  
  // Animasi Logo
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  
  // Animasi Teks
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  
  // Animasi Loading Bar & Tombol
  late final Animation<double> _progressOpacity;
  late final Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();

    // Kontroller utama untuk urutan masuk (Intro)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    // Kontroller untuk efek melayang (Ambient) pada background
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    // --- Definisi Tweens dengan Interval ---

    // 1. Logo muncul duluan (0% - 50%)
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 2. Judul & Slogan (30% - 70%)
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Progress Bar muncul (60% - 85%)
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeIn),
      ),
    );

    // 4. Tombol Masuk muncul terakhir (85% - 100%)
    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInOut),
      ),
    );

    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _handleNavigate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 1000),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: const LoginPage(),
        ),
      ),
    );
  }

  Future<void> _checkSessionAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_sessionLoggedInKey) ?? false;
    final userName = prefs.getString(_sessionUserNameKey) ?? '';

    if (!isLoggedIn || userName.trim().isEmpty || !mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: HomePage(userName: userName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema
    const Color deepTeal = Color(0xFF0F5A4E);
    const Color oceanTeal = Color(0xFF177868);
    const Color mintGlow = Color(0xFF7FE3CC);
    const Color elegantGold = Color(0xFFCBA052);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_introController, _ambientController]),
        builder: (context, child) {
          // Efek gerak lambat untuk background orbs
          final drift = sin(_ambientController.value * pi * 2) * 15;

          return Stack(
            children: [
              // 1. Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [deepTeal, oceanTeal],
                  ),
                ),
              ),

              // 2. Decorative Ambient Orbs
              Positioned(
                top: -100 + drift,
                left: -70,
                child: _GlowOrb(size: 280, color: mintGlow.withOpacity(0.15)),
              ),
              Positioned(
                bottom: -90 - drift,
                right: -60,
                child: _GlowOrb(size: 240, color: elegantGold.withOpacity(0.15)),
              ),

              // 3. Main Content
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo Area
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: _buildLogoContainer(),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title & Slogan Area
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: _buildTextContent(),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Animated Bottom Section (Switching between Progress and Button)
                        SizedBox(
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress Bar: Muncul selama intro, lalu memudar
                              if (_introController.value < 0.9)
                                Opacity(
                                  opacity: _progressOpacity.value,
                                  child: _buildProgressBar(elegantGold),
                                ),

                              // Tombol Masuk: Muncul setelah progress selesai
                              if (_introController.value > 0.8)
                                Opacity(
                                  opacity: _buttonOpacity.value,
                                  child: Transform.translate(
                                    offset: Offset(0, 15 * (1 - _buttonOpacity.value)),
                                    child: _buildEnterButton(elegantGold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoContainer() {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(15),
          child: Image.asset(
            'assets/logo.png', // Ganti sesuai path asetmu
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return const Column(
      children: [
        Text(
          'HIDAYAH HUB',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Belajar, Berbagi, Bertumbuh Bersama',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFBEE3DB),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(Color color) {
    return SizedBox(
      width: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          minHeight: 6,
          backgroundColor: Colors.white.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }

  Widget _buildEnterButton(Color color) {
    return ElevatedButton(
      onPressed: _handleNavigate,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
        shadowColor: color.withOpacity(0.5),
      ),
      child: const Text(
        'MASUK',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}