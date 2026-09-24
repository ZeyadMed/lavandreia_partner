import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/time_picker_sheet.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/working_day_card.dart';
import 'package:lavanderia_partner/features/profile/data/working_hours_data_source.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/working_hours_skeleton.dart';
import 'package:lavanderia_partner/features/profile/presentation/view_model/working_hours_cubits.dart';

/// صفحة مواعيد العمل: بتجيب المواعيد الحالية (GET)
/// والتعديل بيفضل محلي لحد ما اليوزر يضغط حفظ (PUT)
class WorkingHoursScreen extends StatelessWidget {
  const WorkingHoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = getIt<WorkingHoursDataSource>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => WorkingHoursCubit(dataSource)..fetchData()),
        BlocProvider(create: (_) => UpdateWorkingHoursCubit(dataSource)),
      ],
      child: const _WorkingHoursView(),
    );
  }
}

class _WorkingHoursView extends StatefulWidget {
  const _WorkingHoursView();

  @override
  State<_WorkingHoursView> createState() => _WorkingHoursViewState();
}

class _WorkingHoursViewState extends State<_WorkingHoursView> {
  /// نفس الافتراضي بتاع خطوة التسجيل، 9 ص لـ 10 م
  static const _defaultOpen = DateTimeRangePart(hour: 9, minute: 0);
  static const _defaultClose = DateTimeRangePart(hour: 22, minute: 0);

  /// نسخة محلية من المواعيد بتتعدل لحد الحفظ
  List<WorkingDay> _days = [];

  /// الأيام اللي فيها مشكلة بعد محاولة الحفظ
  Set<String> _invalidDays = {};

  /// بيرتب الأيام من السبت للجمعة، واليوم اللي مش راجع من السيرفر بيتحط مقفول
  void _onFetchStateChanged(BuildContext context, BaseState<WorkingDay> state) {
    if (!state.isSuccess) return;
    final byKey = {for (final day in state.items) day.key: day};
    setState(() {
      _invalidDays = {};
      _days = [
        for (final key in WorkingDay.weekDays)
          byKey[key]?.copy() ?? WorkingDay(key: key, isClosed: true),
      ];
    });
  }

  void _toggleClosed(WorkingDay day, bool isClosed) {
    setState(() {
      day.isClosed = isClosed;
      if (isClosed) {
        day.openTime = null;
        day.closeTime = null;
      } else {
        day.openTime ??= _defaultOpen;
        day.closeTime ??= _defaultClose;
      }
      _invalidDays.remove(day.key);
    });
  }

  Future<void> _pickTime(WorkingDay day, {required bool isOpenTime}) async {
    final current = isOpenTime ? day.openTime : day.closeTime;

    final picked = await showAppTimePicker(
      context: context,
      titleKey: isOpenTime ? 'select_open_time' : 'select_close_time',
      initialTime: current ?? (isOpenTime ? _defaultOpen : _defaultClose),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isOpenTime) {
        day.openTime = picked;
      } else {
        day.closeTime = picked;
      }
      _invalidDays.remove(day.key);
    });
  }

  void _save() {
    final invalid = _days
        .where((day) => !day.isValid)
        .map((day) => day.key)
        .toSet();

    if (invalid.isNotEmpty) {
      setState(() => _invalidDays = invalid);
      context.showErrorMessage('set_hours_for_open_days'.tr());
      return;
    }

    if (_days.every((day) => day.isClosed)) {
      context.showErrorMessage('at_least_one_open_day'.tr());
      return;
    }

    context.read<UpdateWorkingHoursCubit>().save(_days);
  }

  void _onSaveStateChanged(BuildContext context, BaseState<void> state) {
    if (state.isSuccess) {
      context.showSuccessMessage('working_hours_saved'.tr());
      return;
    }
    // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
    final failure = state.failure;
    if (state.isFailure &&
        (failure is ServerFailure || failure is UnknownFailure)) {
      context.showErrorMessage(failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WorkingHoursCubit, BaseState<WorkingDay>>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onFetchStateChanged,
        ),
        BlocListener<UpdateWorkingHoursCubit, BaseState<void>>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onSaveStateChanged,
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        appBar: const CustomAppBar(title: 'working_hours'),
        // شريط الحفظ جوه Column مش bottomNavigationBar، لأن الـ Center اللي في
        // CustomButton بيتمد لطول الشاشة هناك والـ SnackBar بيطلع بره الشاشة
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<WorkingHoursCubit, BaseState<WorkingDay>>(
                builder: (context, state) => _buildBody(context, state),
              ),
            ),
            if (_days.isNotEmpty)
              BlocBuilder<UpdateWorkingHoursCubit, BaseState<void>>(
                builder: (context, saveState) =>
                    _SaveBar(isSaving: saveState.isLoading, onSave: _save),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BaseState<WorkingDay> state) {
    final cubit = context.read<WorkingHoursCubit>();
    if (state.isFailure && _days.isEmpty) {
      return _RetryMessage(onRetry: cubit.fetchData);
    }
    if (_days.isEmpty) {
      return const WorkingHoursSkeleton();
    }

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.fetchData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        children: [
          LocalizedLabel(
            text: 'set_working_hours_hint',
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular16.copyWith(
              color: AppColors.greyColor3,
            ),
          ),
          Gap(16.h),
          for (final day in _days)
            WorkingDayCard(
              day: day,
              hasError: _invalidDays.contains(day.key),
              onClosedChanged: (value) => _toggleClosed(day, value),
              onPickOpenTime: () => _pickTime(day, isOpenTime: true),
              onPickCloseTime: () => _pickTime(day, isOpenTime: false),
            ),
        ],
      ),
    );
  }
}

/// رسالة فشل تحميل بزرار إعادة المحاولة
class _RetryMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalizedLabel(
            text: 'working_hours_load_failed',
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(color: AppColors.redColor),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
            label: LocalizedLabel(
              text: 'try_again',
              style: TextStyles.darkBold14.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زرار الحفظ الثابت تحت الصفحة
class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveBar({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 14.h, 5.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: CustomButton(
          // بنقفل الضغط وقت الحفظ عشان مايتبعتش مرتين
          onPressed: isSaving ? () {} : onSave,
          title: isSaving ? 'saving' : 'save_changes',
          backgroundColor: isSaving
              ? AppColors.primaryColor.withValues(alpha: 0.6)
              : AppColors.primaryColor,
        ),
      ),
    );
  }
}
