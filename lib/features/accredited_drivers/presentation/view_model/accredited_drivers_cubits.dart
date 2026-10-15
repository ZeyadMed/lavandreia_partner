import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/accredited_drivers_data_source.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accredited_driver.dart';

/// لستة الدليفرية المعتمدين، الداتا في state.items
/// بعد الاعتماد أو الإلغاء بنحدّثها محلياً بدل ما نجيبها تاني
class AccreditedDriversCubit extends BaseCubit<AccreditedDriver> {
  AccreditedDriversCubit(AccreditedDriversDataSource dataSource)
    : super(fetchFunction: dataSource.getAccreditedDrivers);

  /// الجديد بيتحط في الأول زي ترتيب السيرفر
  void prepend(AccreditedDriver driver) {
    emit(
      state.copyWith(
        items: [
          driver,
          for (final item in state.items)
            if (item.driverId != driver.driverId) item,
        ],
      ),
    );
  }

  void removeDriver(int driverId) {
    emit(
      state.copyWith(
        items: state.items
            .where((item) => item.driverId != driverId)
            .toList(),
      ),
    );
  }
}

/// اعتماد دليفري برقمه، ولما ينجح state.data بيبقى الدليفري اللي اتعتمد
class AccreditDriverCubit extends Cubit<BaseState<AccreditedDriver>> {
  final AccreditedDriversDataSource _dataSource;

  AccreditDriverCubit(this._dataSource)
    : super(const BaseState<AccreditedDriver>());

  Future<void> submit(String phoneNumber) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.accreditDriver(phoneNumber);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (driver) => emit(state.copyWith(status: Status.success, data: driver)),
    );
  }
}

/// إلغاء اعتماد دليفري، والـ data بتفضل شايلة الـ driverId
/// عشان اللودينج يظهر على الكارت بتاعه بس والشاشة تشيله بعد النجاح
class UnaccreditDriverCubit extends Cubit<BaseState<int>> {
  final AccreditedDriversDataSource _dataSource;

  UnaccreditDriverCubit(this._dataSource) : super(const BaseState<int>());

  Future<void> submit(int driverId) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: Status.loading, data: driverId));

    final result = await _dataSource.unaccreditDriver(driverId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (_) => emit(state.copyWith(status: Status.success)),
    );
  }
}
