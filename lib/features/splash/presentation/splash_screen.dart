import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_typography.dart';
import 'widgets/ecg_heartbeat_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ecgController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _ecgAnimation;
  late Animation<double> _pulseScaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. ECG Drawing Animation Controller
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _ecgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ecgController, curve: Curves.easeInOut),
    );

    // 2. Heartbeat Scale Pulse Controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.98), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // 3. Fade-in Controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Trigger ECG drawing animation
    _ecgController.forward();

    // Trigger synchronized pulse right when ECG spike reaches center
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.forward(from: 0.0);
      }
    });

    // Repeat ECG pulse once for visual rhythm
    _ecgController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _ecgController.reset();
            _ecgController.forward();
            _pulseController.forward(from: 0.0);
          }
        });
      }
    });

    // Smooth navigation transition after splash sequence
    Future.delayed(const Duration(seconds: 3, milliseconds: 500), () {
      if (mounted) {
        context.go(RouteNames.loginPath);
      }
    });
  }

  @override
  void dispose() {
    _ecgController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: reduceMotion
              ? const AlwaysStoppedAnimation(1.0)
              : _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Pulsing Central Blood Drop Logo Widget
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = reduceMotion ? 1.0 : _pulseScaleAnimation.value;
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceLG),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      AppIcons.bloodDrop,
                      size: 72,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceLG),

                // BloodBridge App Title
                Text(
                  AppStrings.appName,
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceXS),

                // Primary Tagline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXL),
                  child: Text(
                    'Blood can save a life. Connect. Donate. Save.',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primaryRed,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),

                // Animated ECG Heartbeat Canvas
                SizedBox(
                  width: size.width * 0.85,
                  height: 64,
                  child: AnimatedBuilder(
                    animation: _ecgController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: EcgHeartbeatPainter(
                          progress: reduceMotion ? 1.0 : _ecgAnimation.value,
                          color: AppColors.primaryRed,
                          strokeWidth: 3.2,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceSM),

                // Secondary Subtitle
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
