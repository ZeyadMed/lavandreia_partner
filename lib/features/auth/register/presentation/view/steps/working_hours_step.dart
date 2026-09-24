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
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/working_day_card.dart';

/// الخطوة التالتة: مواعيد العمل لكل يوم في الأسبوع
/// كل يوم له سويتش "مغلق"، ولو مفتوح بيحدد من ساعة لساعة
class WorkingHoursStep extends StatefulWidget {
  final RegisterData data;
  final VoidCallback onNext;

  const WorkingHoursStep({super.key, required this.data, required this.onNext});

  @override
  State<WorkingHoursStep> createState() => _WorkingHoursStepState();
}

class _WorkingHoursStepState extends State<WorkingHoursStep> {
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
        ? widget.data.workingDays.map((day) => day.copy()).toList()
        : WorkingDay.weekDays
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

        ..._days.map(
          (day) => WorkingDayCard(
            day: day,
            hasError: _invalidDays.contains(day.key),
            onClosedChanged: (value) => _toggleClosed(day, value),
            onPickOpenTime: () => _pickTime(day, isOpenTime: true),
            onPickCloseTime: () => _pickTime(day, isOpenTime: false),
          ),
        ),

        Gap(20.h),
        CustomButton(onPressed: _submit, title: 'next'.tr()),
      ],
    );
  }
}
