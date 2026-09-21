import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/time_picker_sheet.dart';

/// الخطوة الرابعة: مواعيد العمل لكل يوم في الأسبوع
/// كل يوم له سويتش "مغلق"، ولو مفتوح بيحدد من ساعة لساعة
class WorkingHoursStep extends StatefulWidget {
  final RegisterData data;
  final VoidCallback onNext;

  const WorkingHoursStep({super.key, required this.data, required this.onNext});

  @override
  State<WorkingHoursStep> createState() => _WorkingHoursStepState();
}

class _WorkingHoursStepState extends State<WorkingHoursStep> {
  /// أيام الأسبوع بترتيب التقويم العربي، السبت أول يوم
  static const List<String> _weekDays = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  /// الأوقات الافتراضية لما اليوزر يبدأ يحدد، 9 ص لـ 10 م
  static const _defaultOpen = DateTimeRangePart(hour: 9, minute: 0);
  static const _defaultClose = DateTimeRangePart(hour: 22, minute: 0);

  late List<WorkingDay> _days;

  /// الأيام اللي فيها مشكلة بعد محاولة الحفظ
  Set<String> _invalidDays = {};

  @override
  void initState() {
    super.initState();
    _days = widget.data.workingDays.isNotEmpty
        // بنرجّع اللي اتحدد قبل كده لو اليوزر رجع خطوة لورا
        // بنسخ مش بالمرجع، عشان التعديل مايتحفظش غير لما الفاليديشن يعدي
        ? widget.data.workingDays
              .map(
                (day) => WorkingDay(
                  key: day.key,
                  isClosed: day.isClosed,
                  openTime: day.openTime,
                  closeTime: day.closeTime,
                ),
              )
              .toList()
        : _weekDays
              .map(
                (key) => WorkingDay(
                  key: key,
                  // الجمعة مقفولة افتراضياً، باقي الأيام مفتوحة بالمواعيد الافتراضية
                  isClosed: key == 'friday',
                  openTime: key == 'friday' ? null : _defaultOpen,
                  closeTime: key == 'friday' ? null : _defaultClose,
                ),
              )
              .toList();
  }

  void _toggleClosed(WorkingDay day, bool isClosed) {
    setState(() {
      day.isClosed = isClosed;
      if (isClosed) {
        day.openTime = null;
        day.closeTime = null;
      } else {
        // بنرجّع الافتراضي عشان اليوزر مايفضلش يحدد من الصفر
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

  void _submit() {
    final invalid = _days
        .where((day) => !day.isValid)
        .map((day) => day.key)
        .toSet();

    if (invalid.isNotEmpty) {
      setState(() => _invalidDays = invalid);
      _showMessage('set_hours_for_open_days');
      return;
    }

    // لازم يوم شغل واحد على الأقل، مغسلة مقفولة طول الأسبوع مالهاش معنى
    if (_days.every((day) => day.isClosed)) {
      _showMessage('at_least_one_open_day');
      return;
    }

    widget.data.workingDays = _days;
    widget.onNext();
  }

  void _showMessage(String messageKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Label(text: messageKey.tr(), style: TextStyles.whiteBold14),
        backgroundColor: AppColors.redColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocalizedLabel(
          text: 'set_working_hours_hint',
          textAlign: TextAlign.center,
          style: TextStyles.darkRegular16.copyWith(color: AppColors.greyColor3),
        ),
        Gap(16.h),

        ..._days.map(_buildDayCard),

        Gap(20.h),
        CustomButton(onPressed: _submit, title: 'next'.tr()),
      ],
    );
  }

  Widget _buildDayCard(WorkingDay day) {
    final hasError = _invalidDays.contains(day.key);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: day.isClosed
              ? Colors.grey.withValues(alpha: 0.06)
              : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasError
                ? AppColors.redColor
                : day.isClosed
                ? Colors.grey.withValues(alpha: 0.25)
                : AppColors.primaryColor.withValues(alpha: 0.35),
            width: hasError ? 1.4 : 0.9,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LocalizedLabel(
                    text: day.key,
                    style: TextStyles.blackBold16.copyWith(
                      color: day.isClosed
                          ? AppColors.greyColor3
                          : AppColors.darkTextColor,
                    ),
                  ),
                ),
                LocalizedLabel(
                  text: 'closed',
                  style: TextStyles.darkRegular14.copyWith(
                    color: day.isClosed
                        ? AppColors.redColor
                        : AppColors.greyColor4,
                  ),
                ),
                Gap(4.w),
                Switch(
                  value: day.isClosed,
                  activeThumbColor: AppColors.redColor,
                  onChanged: (value) => _toggleClosed(day, value),
                ),
              ],
            ),
            // الساعات بتختفي خالص لما اليوم يبقى مقفول
            if (!day.isClosed) ...[
              Gap(6.h),
              Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      labelKey: 'from',
                      time: day.openTime,
                      onTap: () => _pickTime(day, isOpenTime: true),
                    ),
                  ),
                  Gap(10.w),
                  Expanded(
                    child: _TimeBox(
                      labelKey: 'to',
                      time: day.closeTime,
                      onTap: () => _pickTime(day, isOpenTime: false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// خانة الوقت الواحدة: "من" أو "إلى" وتحتها الساعة المختارة
class _TimeBox extends StatelessWidget {
  final String labelKey;
  final DateTimeRangePart? time;
  final VoidCallback onTap;

  const _TimeBox({
    required this.labelKey,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(10.r),
          border: const Border.fromBorderSide(
            BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16.sp,
              color: AppColors.primaryColor,
            ),
            Gap(6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedLabel(
                    text: labelKey,
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.greyColor3,
                    ),
                  ),
                  Label(
                    text: time?.toLocalizedString() ?? '--:--',
                    style: TextStyles.darkBold14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
