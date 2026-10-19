import 'dart:async';

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
import 'package:lavanderia_partner/features/profile/data/working_hours_status.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/discard_changes_dialog.dart';
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

  /// آخر مواعيد متسجلة على السيرفر، منها بنعرف لو فيه تعديل لسه ماتحفظش
  /// ومنها بتتحسب حالة "مفتوح الآن"
  List<WorkingDay> _savedDays = [];

  /// الأيام اللي فيها مشكلة بعد محاولة الحفظ
  Set<String> _invalidDays = {};

  bool get _hasUnsavedChanges {
    if (_days.length != _savedDays.length) return true;
    for (var i = 0; i < _days.length; i++) {
      if (!_days[i].hasSameHoursAs(_savedDays[i])) return true;
    }
    return false;
  }

  /// بيرتب الأيام من السبت للجمعة، واليوم اللي مش راجع من السيرفر بيتحط مقفول
  void _onFetchStateChanged(BuildContext context, BaseState<WorkingDay> state) {
    if (!state.isSuccess) return;
    final byKey = {for (final day in state.items) day.key: day};
    final days = [
      for (final key in WorkingDay.weekDays)
        byKey[key] ?? WorkingDay(key: key, isClosed: true),
    ];
    setState(() {
      _invalidDays = {};
      _days = [for (final day in days) day.copy()];
      _savedDays = [for (final day in days) day.copy()];
    });
  }

  /// الساعات بتفضل محفوظة وهو مقفول، فلو رجّع اليوم يلاقي اللي كان محدده
  /// ومابتتبعتش للسيرفر طول ما اليوم مقفول
  void _toggleClosed(WorkingDay day, bool isClosed) {
    setState(() {
      day.isClosed = isClosed;
      if (!isClosed) {
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
      opensAt: isOpenTime ? null : day.openTime,
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
      context.showErrorMessage(
        (_days.any((day) => !day.isClosed && day.hasSameOpenAndClose)
                ? 'open_close_same_time'
                : 'set_hours_for_open_days')
            .tr(),
      );
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
      setState(() => _savedDays = [for (final day in _days) day.copy()]);
      context.showSuccessMessage('working_hours_saved'.tr());
      // بنجيب من السيرفر تاني عشان اللي معروض يبقى هو المتسجل فعلاً
      context.read<WorkingHoursCubit>().fetchData();
      return;
    }
    // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
    final failure = state.failure;
    if (state.isFailure &&
        (failure is ServerFailure || failure is UnknownFailure)) {
      context.showErrorMessage(failure!.message);
    }
  }

  /// الرجوع بتعديلات مش محفوظة بيسأل الأول، عشان اليوزر مايفتكرش إنها اتحفظت
  Future<void> _confirmLeave() async {
    final discard = await showDiscardChangesDialog(context);
    if (discard == true && mounted) Navigator.of(context).pop();
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
      child: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave();
        },
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
          _OpenStatusBanner(days: _savedDays),
          Gap(16.h),
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

/// "مفتوح الآن / مغلق الآن" حسب المواعيد المحفوظة وساعة ليبيا
/// بيتحدث كل شوية لوحده عشان يقلب في ميعاد الفتح والقفل من غير ما اليوزر يعمل حاجة
class _OpenStatusBanner extends StatefulWidget {
  final List<WorkingDay> days;

  const _OpenStatusBanner({required this.days});

  @override
  State<_OpenStatusBanner> createState() => _OpenStatusBannerState();
}

class _OpenStatusBannerState extends State<_OpenStatusBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 20),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// "يغلق 2:00 AM" أو "يفتح غداً 9:00 AM"
  String? _detail(WorkingHoursStatus status, DateTime now) {
    final at = status.changesAt;
    if (at == null) return null;
    final time = DateTimeRangePart(
      hour: at.hour,
      minute: at.minute,
    ).toDisplayString();
    if (status.isOpen) {
      // القفل غالباً خلال ساعات، فاليوم مش محتاج يتكتب إلا لو بعيد
      final when = at.difference(now) > const Duration(days: 1)
          ? '${_dayLabel(at, now)} $time'
          : time;
      return 'closes_at'.tr(args: [when]);
    }
    return 'opens_at'.tr(args: ['${_dayLabel(at, now)} $time']);
  }

  String _dayLabel(DateTime date, DateTime now) {
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'today'.tr();
    if (days == 1) return 'tomorrow'.tr();
    return WorkingHoursStatus.weekdayKey(date).tr();
  }

  @override
  Widget build(BuildContext context) {
    final now = laundryNow();
    final status = WorkingHoursStatus.at(widget.days, now);
    final color = status.isOpen ? AppColors.greenColor : AppColors.redColor;
    final detail = _detail(status, now);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.9),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LocalizedLabel(
                      text: status.isOpen ? 'open_now' : 'closed_now',
                      style: TextStyles.darkBold14.copyWith(color: color),
                    ),
                    if (detail != null) ...[
                      Gap(6.w),
                      Flexible(
                        child: Label(
                          text: '· $detail',
                          style: TextStyles.darkRegular14,
                        ),
                      ),
                    ],
                  ],
                ),
                Gap(2.h),
                LocalizedLabel(
                  text: 'working_status_note',
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
              ],
            ),
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
