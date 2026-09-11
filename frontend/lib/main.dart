import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'theme/app_colors.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_step1_screen.dart';
import 'screens/onboarding_step2_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OurlyApp());
}

class OurlyApp extends StatelessWidget {
  const OurlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: 'Ourly',
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadRoseColorScheme.light(),
      ),
      materialThemeBuilder: (context, theme) {
        return theme.copyWith(
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(theme.textTheme),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            surface: AppColors.background,
          ),
        );
      },
      home: const MainNavigationController(),
    );
  }
}

enum AppFlowState {
  auth,
  onboardingStep1,
  onboardingStep2,
  dashboard,
}

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});

  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  final _apiService = ApiService();
  AppFlowState _currentState = AppFlowState.auth;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    // Check if user is logged in
    if (_apiService.currentUser != null) {
      final couple = await _apiService.getCurrentCouple();
      if (couple != null) {
        _currentState = AppFlowState.dashboard;
      } else {
        _currentState = AppFlowState.onboardingStep1;
      }
    } else {
      _currentState = AppFlowState.auth;
    }

    if (mounted) {
      setState(() => _isCheckingSession = false);
    }
  }

  void _onAuthenticated() async {
    setState(() => _isCheckingSession = true);
    final couple = await _apiService.getCurrentCouple();
    setState(() {
      _isCheckingSession = false;
      if (couple != null) {
        _currentState = AppFlowState.dashboard;
      } else {
        _currentState = AppFlowState.onboardingStep1;
      }
    });
  }

  void _onStep1Completed() {
    setState(() {
      _currentState = AppFlowState.onboardingStep2;
    });
  }

  void _onStep2Completed() {
    setState(() {
      _currentState = AppFlowState.dashboard;
    });
  }

  void _onLogout() {
    _apiService.logout();
    setState(() {
      _currentState = AppFlowState.auth;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    switch (_currentState) {
      case AppFlowState.auth:
        return AuthScreen(onAuthenticated: _onAuthenticated);
      case AppFlowState.onboardingStep1:
        return OnboardingStep1Screen(
          onNext: _onStep1Completed,
          onSkipToHome: () => setState(() => _currentState = AppFlowState.dashboard),
          onBack: () => setState(() => _currentState = AppFlowState.auth),
        );
      case AppFlowState.onboardingStep2:
        return OnboardingStep2Screen(
          onEnterSpace: _onStep2Completed,
          onBack: () => setState(() => _currentState = AppFlowState.onboardingStep1),
        );
      case AppFlowState.dashboard:
        return DashboardScreen(
          onLogout: _onLogout,
          onShowInvite: () => setState(() => _currentState = AppFlowState.onboardingStep2),
        );
    }
  }
}
