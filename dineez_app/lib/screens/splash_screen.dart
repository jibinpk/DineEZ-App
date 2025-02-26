import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

import '../config/constants.dart';
import '../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    
    // Log splash screen viewing
    ref.read(logInfoProvider)('Splash screen shown', source: 'SplashScreen');
    
    // Initialize sequence of operations
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Update global loading state
      ref.read(globalLoadingProvider.notifier).state = true;
      
      // Delay for minimum splash screen time
      await Future.delayed(const Duration(seconds: 2));
      
      // Get auth state and user preferences
      final authState = ref.read(authProvider);
      final preferences = ref.read(appPreferencesProvider);
      
      if (!mounted) return;
      
      // Navigate to appropriate screen
      if (authState.user != null) {
        // User is authenticated, navigate to dashboard
        Navigator.of(context).pushReplacementNamed(AppConstants.routeDashboard);
      } else if (!preferences.onboardingCompleted) {
        // User hasn't completed onboarding
        Navigator.of(context).pushReplacementNamed(AppConstants.routeOnboarding);
      } else {
        // Navigate to login screen
        Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
      }
    } catch (e) {
      // Log error
      ref.read(logErrorProvider)('Error in splash screen initialization', source: 'SplashScreen', data: e);
      
      // Show error in global error provider
      ref.read(globalErrorProvider.notifier).state = 'Failed to initialize app: $e';
      
      // Still navigate to login after error
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
      }
    } finally {
      // Update global loading state
      ref.read(globalLoadingProvider.notifier).state = false;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'DineEZ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Loading spinner
              SpinKitPulse(
                color: Colors.white,
                size: 50.0,
              ),
              
              const SizedBox(height: 20),
              
              // App tagline
              const Text(
                'Scan. Order. Enjoy.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 