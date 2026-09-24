import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/router/bottom_nav_app.dart';
import 'package:lavanderia_partner/features/auth/change_password/presentation/view/change_password_screen.dart';
import 'package:lavanderia_partner/features/auth/forget_password/presentation/view/forget_password_screen.dart';
import 'package:lavanderia_partner/features/auth/login/presentation/view/login_screen.dart';
import 'package:lavanderia_partner/features/auth/otp/presentation/view/otp_screen.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/register_screen.dart';
import 'package:lavanderia_partner/features/on_boarding/presentation/views/on_boarding_screen.dart';
import 'package:lavanderia_partner/features/services/presentation/view/setup_services_screen.dart';
import 'package:lavanderia_partner/features/splash/presentation/view/splash_screen.dart';
import 'package:lavanderia_partner/main.dart';

abstract class AppRouter {
  static const String root = '/';
  static const String webViewContainer = '/webViewContainer';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/signUp';
  static const String forgetPassword = '/forgetPassword';
  static const String verifyOtp = '/verifyOtp';
  static const String changePassword = '/changePassword';
  static const String setupServices = '/setupServices';
  static const String resetPasswordScreen = '/resetPasswordScreen';
  static const String successScreen = '/successScreen';
  // ************* HOME *************
  static const String initialRoot = '/initialRoot';
  static const String homeScreen = '/HomeScreen';
  static const String laundryDetails = '/laundryDetails';
  static const String orderPending = '/orderPending';
  static const String confirmOrder = '/confirmOrder';
  static const String rejectOrder = '/rejectOrder';

  // ************* PROFILE *************
  static const String orderScreen = '/orderScreen';
  static const String orderDetails = '/orderDetails';
  static const String profileScreen = '/profileScreen';
  static const String contactUsScreen = '/contactUsScreen';
  static const String notificationScreen = '/notificationScreen';
  static const String customerServiceScreen = '/customerServiceScreen';
  static const String aboutUs = '/aboutUs';
  static const String updateProfileScreen = '/updateProfileScreen';
  static const String privacyPolicy = '/privacyPolicy';
  static const String comingSoonScreen = '/CommingSoonScreen';

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    routes: [
      // -----------------------------------Splash Screen and OnBoarding--------------------------------
      GoRoute(path: root, builder: (context, state) => const SplashScreen()),
      //  GoRoute(
      //     path: webViewContainer,
      //     builder: (context, state) {
      //       final extra = state.extra;
      //       String url = '';
      //       if (extra is String) {
      //         url = extra;
      //       } else if (extra is Map<String, dynamic>) {
      //         url = (extra['url'] ?? '') as String;
      //       } else if (extra is Map) {
      //         url = (extra['url'] ?? '') as String;
      //       }
      //       return WebViewContainer(
      //         url: url,
      //       );
      //     },
      //   ),
      GoRoute(
        path: initialRoot,
        builder: (context, state) => const BottomNavApp(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // -----------------------------------Auth--------------------------------
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: signUp,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: verifyOtp,
        // الرقم بييجي من التسجيل بس، ومن نسيت كلمة المرور بيبقى null
        builder: (context, state) =>
            OtpScreen(phoneNumber: state.extra as String?),
      ),
      GoRoute(
        path: forgetPassword,
        builder: (context, state) => const ForgetPasswordScreen(),
      ),
      GoRoute(
        path: changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: setupServices,
        builder: (context, state) => const SetupServicesScreen(),
      ),
    ],
  );
}
