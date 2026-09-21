import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';

/// بوتوم شيت لاختيار الوقت بعجلات 12 ساعة
/// اتعمل بدل showTimePicker لأن الأخير بيرسم دايرتين ساعات
/// (0-11 جوه و 12-23 بره) لما الجهاز بنظام 24 ساعة، والأرقام بتركب فوق بعض
/// وكمان العرض عندنا 12 ساعة بـ ص/م فالأنسب إن الاختيار يبقى بنفس الشكل
Future<DateTimeRangePart?> showAppTimePicker({
  required BuildContext context,
  required String titleKey,
  DateTimeRangePart? initialTime,
}) {
  return showModalBottomSheet<DateTimeRangePart>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TimePickerSheet(
      titleKey: titleKey,
      initialTime: initialTime ?? const DateTimeRangePart(hour: 9, minute: 0),
    ),
  );
}

class _TimePickerSheet extends StatefulWidget {
  final String titleKey;
  final DateTimeRangePart initialTime;

  const _TimePickerSheet({required this.titleKey, required this.initialTime});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  /// ارتفاع الصف الواحد في العجلة
  static const double _itemExtent = 46;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  /// الساعة بنظام 12، من 1 لـ 12
  late int _hour12;
  late int _minute;

  /// true يعني صباحاً
  late bool _isAm;

  @override
  void initState() {
    super.initState();
    final hour24 = widget.initialTime.hour;
    _isAm = hour24 < 12;
    // 0 و 12 الاتنين بيتعرضوا 12 في نظام 12 ساعة
    _hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    _minute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  /// بيحول الـ 12 ساعة + ص/م لـ 24 ساعة اللي الموديل بيخزنها
  DateTimeRangePart get _result {
    var hour24 = _hour12 % 12;
    if (!_isAm) hour24 += 12;
    return DateTimeRangePart(hour: hour24, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(10.h),
            _buildGrabber(),
            Gap(14.h),
            LocalizedLabel(
              text: widget.titleKey,
              style: TextStyles.blackBold16,
            ),
            Gap(4.h),
            // معاينة حية للوقت المختار عشان اليوزر يتأكد قبل ما يحفظ
            Label(
              text: _result.toLocalizedString(),
              style: TextStyles.blueBold20,
            ),
            Gap(12.h),
            _buildWheels(),
            Gap(8.h),
            _buildPeriodToggle(),
            Gap(18.h),
            CustomButton(
              onPressed: () => Navigator.of(context).pop(_result),
              title: 'confirm'.tr(),
            ),
            Gap(12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildGrabber() {
    return Container(
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppColors.greyColor5,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildWheels() {
    return SizedBox(
      height: _itemExtent.h * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الشريط اللي بيحدد الصف المختار، وراء العجلات
          Container(
            height: _itemExtent.h,
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          // الساعات على الشمال والدقايق على اليمين في الحالتين
          // عشان ترتيب الوقت مايتقلبش مع اتجاه اللغة
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 78.w,
                  child: _buildWheel(
                    controller: _hourController,
                    count: 12,
                    // العجلة بتبدأ من 0 والساعات من 1
                    labelOf: (index) => '${index + 1}',
                    onSelected: (index) =>
                        setState(() => _hour12 = index + 1),
                  ),
                ),
                Label(text: ':', style: TextStyles.blackBold20),
                SizedBox(
                  width: 78.w,
                  child: _buildWheel(
                    controller: _minuteController,
                    count: 60,
                    labelOf: (index) => index.toString().padLeft(2, '0'),
                    onSelected: (index) => setState(() => _minute = index),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int index) labelOf,
    required void Function(int index) onSelected,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent.h,
      physics: const FixedExtentScrollPhysics(),
      // بيخلي العجلة مسطحة شوية بدل الانحناء المبالغ فيه
      diameterRatio: 1.4,
      perspective: 0.003,
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildLoopingListDelegate(
        children: List.generate(count, (index) {
          return Center(
            child: Label(
              text: labelOf(index),
              style: TextStyles.blackBold20.copyWith(fontSize: 22.sp),
            ),
          );
        }),
      ),
    );
  }

  /// اختيار صباحاً / مساءً كزرارين بدل ما يبقى عمود تالت في العجلة
  Widget _buildPeriodToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPeriodOption(labelKey: 'am', isAm: true)),
          Expanded(child: _buildPeriodOption(labelKey: 'pm', isAm: false)),
        ],
      ),
    );
  }

  Widget _buildPeriodOption({required String labelKey, required bool isAm}) {
    final isSelected = _isAm == isAm;

    return GestureDetector(
      onTap: () => setState(() => _isAm = isAm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Center(
          child: LocalizedLabel(
            text: labelKey,
            style: TextStyles.darkBold14.copyWith(
              color: isSelected ? AppColors.whiteColor : AppColors.greyColor3,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
