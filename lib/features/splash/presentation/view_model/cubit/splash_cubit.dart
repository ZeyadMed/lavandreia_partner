import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashCubit extends Cubit<String> {
  SplashCubit() : super('');

  Future<void> startSplashScreen() async {
    // ننتظر لحد ما فيديو السبلاش يخلص (9.4 ثانية).
    await Future.delayed(const Duration(milliseconds: 3000));

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    // بنعتمد على الـ refreshToken مش الـ accessToken: الأكسس بيقع بسرعة
    // والريفريش هو اللي بيحدد إن الجلسة لسه عايشة، والانترسبتور هيجدد لوحده.
    final String? refreshToken = await CacheManager.getRefreshToken();
    // If the user hasn't seen onboarding yet, show it first.
    if (!hasSeenOnboarding) {
      emit('onboarding');
      return;
    }

    // If the session is still alive, go to home. Otherwise, go to login.
    if (refreshToken != null && refreshToken.isNotEmpty) {
      // لو قفل الأبلكيشن قبل ما يخلص إعداد الخدمات، بيرجعله تاني
      emit(CacheManager.hasCompletedServicesSetup() ? 'home' : 'setupServices');
    } else {
      emit('login');
    }
  }

  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuestMode', true);
  }

  // Method to disable Guest mode
  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuestMode', false);
  }
}
