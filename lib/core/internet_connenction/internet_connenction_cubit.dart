import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/internet_connenction/internet_connection_state.dart';

class InternetCubit extends Cubit<InternetState> {
  final Connectivity connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? streamSubscription;

  InternetCubit() : super(const InternetInitialState()) {
    _checkConnectivity();
    _startListening();
  }

  Future<void> _checkConnectivity() async {
    final result = await connectivity.checkConnectivity();
    _emitConnectionState(result);
  }

  /// زرار إعادة المحاولة في شاشة انقطاع النت؛ بيرجع true لو النت رجع.
  /// بيجرب يوصل للسيرفر فعلاً بدل ما يسأل connectivity_plus تاني، لأنها ممكن
  /// تفضل شايلة "مفيش شبكة" بعد ما النت يرجع (زي الـ iOS Simulator)،
  /// وساعتها الـ state بتفضل Off زي ما هي والزرار كأنه مابيعملش حاجة
  Future<bool> retry() async {
    final online = await _canReachInternet();
    log(online ? 'Retry: internet is back' : 'Retry: still offline');
    emit(online ? const InternetOnState() : const InternetOffState());
    return online;
  }

  /// السيرفر الأول، ولو هو واقع والنت شغال جوجل بتأكد إن المشكلة مش في النت
  static Future<bool> _canReachInternet() async {
    final hosts = [Uri.parse(Endpoints.baseUrl).host, 'google.com'];
    for (final host in hosts) {
      try {
        final socket = await Socket.connect(
          host,
          443,
          timeout: const Duration(seconds: 5),
        );
        socket.destroy();
        return true;
      } catch (_) {}
    }
    return false;
  }

  void _startListening() {
    streamSubscription = connectivity.onConnectivityChanged.listen((result) {
      _emitConnectionState(result);
    });
  }

  void _emitConnectionState(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn)) {
      log('Internet connection is available');
      emit(const InternetOnState());
    } else {
      log('No internet connection');
      emit(const InternetOffState());
    }
  }

  @override
  Future<void> close() {
    streamSubscription?.cancel();
    return super.close();
  }
}
