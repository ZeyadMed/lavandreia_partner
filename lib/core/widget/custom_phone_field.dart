import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';

import 'dart:ui' as ui;

import 'package:lavanderia_partner/core/theme/text_styles.dart';

class CustomPhoneField extends StatelessWidget {
  final void Function(PhoneNumber)? onChanged;
  final String? Function(String?)? validator;
  final TextEditingController? controller;

  /// كود الدولة اللي الحقل بيفتح بيه، ليبيا هي الافتراضي
  final String initialCountryCode;

  const CustomPhoneField({
    super.key,
    this.onChanged,
    this.validator,
    this.controller,
    this.initialCountryCode = 'LY',
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: IntlPhoneField(
        controller: controller,
        initialCountryCode: initialCountryCode,
        validator: validator == null
            ? null
            : (phone) => validator!(phone?.number),
        style: TextStyles.darkRegular16,
        dropdownTextStyle: TextStyles.darkRegular16,
        dropdownDecoration: const BoxDecoration(),
        disableLengthCheck: false,
        disableAutoFillHints: false,
        keyboardType: TextInputType.phone,
        languageCode: 'ar',
        pickerDialogStyle: PickerDialogStyle(
          countryNameStyle: TextStyles.blackBold16,
          countryCodeStyle: TextStyles.blackBold14,
          searchFieldPadding: const EdgeInsets.all(5),
        ),
        invalidNumberMessage: "invalidPhoneNumber".tr(),
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            vertical: 12.h,
            horizontal: 20.w,
          ),
          hintText: "XXXXXXXXXXX",
          fillColor: AppColors.secondaryColor,
          filled: true,
          hintStyle: TextStyles.greyColor2Regular14.copyWith(
            // color: const Color(0xff8b7454),
            fontSize: 14.sp,
          ),
          // prefixIconColor: const Color(0xff8b7454),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(
              color: AppColors.primaryColor,
              width: 0.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
