import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/services/data/models/laundry_service.dart';

/// بوتوم شيت تعديل سعر خدمة واحدة
/// بيرجّع السعر الجديد كـ String، أو null لو اتقفل من غير تأكيد
Future<String?> showEditServicePriceSheet({
  required BuildContext context,
  required LaundryService service,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _EditServicePriceSheet(service: service),
  );
}

class _EditServicePriceSheet extends StatefulWidget {
  final LaundryService service;

  const _EditServicePriceSheet({required this.service});

  @override
  State<_EditServicePriceSheet> createState() => _EditServicePriceSheetState();
}

class _EditServicePriceSheetState extends State<_EditServicePriceSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.service.price,
  );

  /// بيتعلّم بالأحمر لو اليوزر حاول يحفظ سعر فاضي أو صفر
  bool _hasError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final price = _controller.text.trim();
    if ((double.tryParse(price) ?? 0) <= 0) {
      setState(() => _hasError = true);
      return;
    }
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // عشان الشيت يطلع فوق الكيبورد
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // المقبض الرمادي الصغير فوق
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
              text: 'edit_service_price',
              textAlign: TextAlign.center,
              style: TextStyles.boldStyle(18, weight: FontWeight.w800),
            ),
            Gap(6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Label(
                  text: widget.service.emoji,
                  style: TextStyle(fontSize: 16.sp),
                ),
                Gap(6.w),
                LocalizedLabel(
                  text: widget.service.labelKey,
                  style: TextStyles.darkRegular14.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
              ],
            ),
            Gap(20.h),
            _PriceField(
              controller: _controller,
              hasError: _hasError,
              onChanged: () {
                if (!_hasError) return;
                setState(() => _hasError = false);
              },
              onSubmitted: _submit,
            ),
            if (_hasError) ...[
              Gap(8.h),
              LocalizedLabel(
                text: 'enter_valid_price',
                textAlign: TextAlign.center,
                style: TextStyles.darkRegular12.copyWith(
                  color: AppColors.redColor,
                ),
              ),
            ],
            Gap(22.h),
            CustomButton(onPressed: _submit, title: 'save'),
          ],
        ),
      ),
    );
  }
}

/// حقل السعر: أرقام إنجليزي بس وفاصلة عشرية واحدة بحد أقصى رقمين بعدها
class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  const _PriceField({
    required this.controller,
    required this.hasError,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      // الـ $ في الريجيكس مهم عشان التحقق يبقى على القيمة كلها مش جزء منها
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        TextInputFormatter.withFunction(
          (oldValue, newValue) =>
              RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)
              ? newValue
              : oldValue,
        ),
      ],
      textAlign: TextAlign.center,
      style: TextStyles.boldStyle(20, weight: FontWeight.w700),
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyles.greyColor2Regular14,
        filled: true,
        fillColor: AppColors.filledColor,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
        suffixText: 'currency_sar'.tr(),
        suffixStyle: TextStyles.darkBold14,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.semiWhiteColor2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: hasError ? AppColors.redColor : AppColors.semiWhiteColor2,
            width: hasError ? 1.2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: hasError ? AppColors.redColor : AppColors.primaryColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
