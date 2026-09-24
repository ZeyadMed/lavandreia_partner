import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/profile/data/working_hours_data_source.dart';

/// مواعيد العمل الحالية، الداتا بتبقى في state.items
class WorkingHoursCubit extends BaseCubit<WorkingDay> {
  WorkingHoursCubit(WorkingHoursDataSource dataSource)
    : super(fetchFunction: dataSource.getWorkingHours);
}

/// PUT بالمواعيد الجديدة، الـ status بس هو اللي بيفرق
class UpdateWorkingHoursCubit extends Cubit<BaseState<void>> {
  final WorkingHoursDataSource _dataSource;

  UpdateWorkingHoursCubit(this._dataSource) : super(const BaseState<void>());

  Future<void> save(List<WorkingDay> days) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.updateWorkingHours(days);
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
