import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/preparation_time.dart';

/// المدد الجاهزة بالدقايق: 3 و 4 و 6 و 12 ساعة، ويوم ويومين و 3 أيام
const List<int> _presetMinutes = [180, 240, 360, 720, 1440, 2880, 4320];

/// شيت مدة التجهيز اللي بيظهر قبل قبول الطلب
/// بيرجّع المدة بالدقايق، أو null لو اتقفل من غير تأكيد
Future<int?> showPreparationDurationSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _PreparationDurationSheet(),
  );
}

class _PreparationDurationSheet extends StatefulWidget {
  const _PreparationDurationSheet();

  @override
  State<_PreparationDurationSheet> createState() =>
      _PreparationDurationSheetState();
}

class _PreparationDurationSheetState extends State<_PreparationDurationSheet> {
  final TextEditingController _customController = TextEditingController();

  /// المدة الجاهزة المختارة، null لو "مدة أخرى" هي المختارة أو لسه مفيش
  int? _preset;
  bool _isCustom = false;

  /// المدة المكتوبة بالأيام بدل الساعات
  bool _customInDays = false;

  bool _hasError = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  int? get _customMinutes {
    final value = int.tryParse(_customController.text.trim());
    if (value == null || value <= 0) return null;
    return value * (_customInDays ? 1440 : 60);
  }

  int? get _selectedMinutes => _isCustom ? _customMinutes : _preset;

  void _selectPreset(int minutes) => setState(() {
    _preset = minutes;
    _isCustom = false;
    _hasError = false;
  });

  void _selectCustom() => setState(() {
    _preset = null;
    _isCustom = true;
    _hasError = false;
  });

  void _submit() {
    final minutes = _selectedMinutes;
    if (minutes == null ||
        minutes < minPreparationMinutes ||
        minutes > maxPreparationMinutes) {
      setState(() => _hasError = true);
      return;
    }
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // عشان الشيت يطلع فوق الكيبورد لما المدة تتكتب
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20.w,
          12.h,
          20.w,
          MediaQuery.of(context).padding.bottom + 20.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.semiWhiteColor2,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Gap(18.h),
              LocalizedLabel(
                text: 'choose_preparation_duration',
                textAlign: TextAlign.center,
                style: TextStyles.boldStyle(18, weight: FontWeight.w800),
              ),
              Gap(6.h),
              LocalizedLabel(
                text: 'preparation_duration_hint',
                textAlign: TextAlign.center,
                style: TextStyles.darkRegular14.copyWith(
                  color: AppColors.greyColor3,
                ),
              ),
              Gap(20.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 10.h,
                alignment: WrapAlignment.center,
                children: [
                  for (final minutes in _presetMinutes)
                    _DurationChip(
                      text: formatPreparationDuration(minutes),
                      isSelected: !_isCustom && _preset == minutes,
                      onTap: () => _selectPreset(minutes),
                    ),
                  _DurationChip(
                    text: 'other_duration'.tr(),
                    isSelected: _isCustom,
                    onTap: _selectCustom,
                  ),
                ],
              ),
              if (_isCustom) ...[
                Gap(16.h),
                _CustomDurationField(
                  controller: _customController,
                  inDays: _customInDays,
                  hasError: _hasError,
                  onUnitChanged: (inDays) => setState(() {
                    _customInDays = inDays;
                    _hasError = false;
                  }),
                  onChanged: () => setState(() => _hasError = false),
                  onSubmitted: _submit,
                ),
              ],
              if (_hasError) ...[
                Gap(8.h),
                LocalizedLabel(
                  text: 'enter_valid_preparation_duration',
                  textAlign: TextAlign.center,
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.redColor,
                  ),
                ),
              ],
              Gap(22.h),
              Opacity(
                opacity: _selectedMinutes == null ? 0.5 : 1,
                child: CustomButton(onPressed: _submit, title: 'confirm_accept'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.1)
              : AppColors.filledColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryColor
                : AppColors.semiWhiteColor2,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Label(
          text: text,
          style: TextStyles.boldStyle(
            14,
            color: isSelected ? AppColors.primaryColor : null,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// حقل المدة اليدوية: رقم صحيح وجنبه اختيار ساعات أو أيام
class _CustomDurationField extends StatelessWidget {
  final TextEditingController controller;
  final bool inDays;
  final bool hasError;
  final ValueChanged<bool> onUnitChanged;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  const _CustomDurationField({
    required this.controller,
    required this.inDays,
    required this.hasError,
    required this.onUnitChanged,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.redColor
        : AppColors.semiWhiteColor2;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18, weight: FontWeight.w700),
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyles.greyColor2Regular14,
              filled: true,
              fillColor: AppColors.filledColor,
              contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: hasError ? AppColors.redColor : AppColors.primaryColor,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        Gap(10.w),
        _DurationChip(
          text: 'unit_hours'.tr(),
          isSelected: !inDays,
          onTap: () => onUnitChanged(false),
        ),
        Gap(8.w),
        _DurationChip(
          text: 'unit_days'.tr(),
          isSelected: inDays,
          onTap: () => onUnitChanged(true),
        ),
      ],
    );
  }
}
