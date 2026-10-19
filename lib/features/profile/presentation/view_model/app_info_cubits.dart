import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/features/profile/data/app_info_data_source.dart';
import 'package:lavanderia_partner/features/profile/data/models/privacy_policy.dart';
import 'package:lavanderia_partner/features/profile/data/models/support_contacts.dart';

/// وسائل التواصل مع الدعم، الداتا بتبقى في state.data
class SupportContactsCubit extends Cubit<BaseState<SupportContacts>> {
  final AppInfoDataSource _dataSource;

  SupportContactsCubit(this._dataSource)
    : super(const BaseState<SupportContacts>());

  Future<void> fetch() async {
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.getContacts();
    // اليوزر ممكن يقفل الشاشة قبل ما الريسبونس يرجع
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(status: Status.failure, errorMessage: failure.message),
      ),
      (contacts) => emit(state.copyWith(status: Status.success, data: contacts)),
    );
  }
}

/// سياسة الخصوصية، الداتا بتبقى في state.data
class PrivacyPolicyCubit extends Cubit<BaseState<PrivacyPolicy>> {
  final AppInfoDataSource _dataSource;

  PrivacyPolicyCubit(this._dataSource)
    : super(const BaseState<PrivacyPolicy>());

  Future<void> fetch() async {
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.getPrivacyPolicy();
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(status: Status.failure, errorMessage: failure.message),
      ),
      (policy) => emit(state.copyWith(status: Status.success, data: policy)),
    );
  }
}
