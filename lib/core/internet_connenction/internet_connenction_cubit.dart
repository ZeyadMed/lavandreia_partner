import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lavanderia_partner/core/internet_connenction/internet_connection_state.dart';

class InternetCubit extends Cubit<InternetState> {
  final Connectivity connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? streamSubscription;

  InternetCubit() : super(const InternetInitialState()) {
    _checkConnectivity();
    _startListening();
  }

  void _checkConnectivity() async {
    final result = await connectivity.checkConnectivity();
    _emitConnectionState(result);
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
