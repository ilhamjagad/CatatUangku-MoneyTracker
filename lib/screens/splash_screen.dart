import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../utils/constants.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

/// Layar pembuka yang menampilkan logo dan cek status login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller untuk fade in
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Mulai animasi
    _animationController.forward();

    // Cek status login dan redirect
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // Tunggu animasi splash selesai
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // ✅ Tunggu Firebase Auth emit state pertama (null atau user)
    final user = await firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .first;

    if (!mounted) return;

    if (user != null) {
      _navigateToScreen(const MainNavigation());
    } else {
      _navigateToScreen(const LoginScreen());
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.surfaceLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated gradient logo dengan shadow premium
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut),
                    ),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: AppColors.primaryMid.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 70,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App Name dengan animasi
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline dengan gradient text effect
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.secondaryGradient.createShader(bounds),
                    child: Text(
                      'Kelola keuanganmu dengan mudah',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryMid,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryDark.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}