import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';

class IntelPhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? hintText;
  final String? initialValue;
  final Function(String)? onPhoneChanged; // Callback لتمرير الرقم الكامل

  const IntelPhoneTextField({
    super.key,
    this.controller,
    this.validator,
    this.hintText,
    this.onPhoneChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      decoration: InputDecoration(
        hintText: hintText ?? '01xxxxxxxxx',
        hintStyle: const TextStyle(
          color: AppColors.hintTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      initialValue: initialValue ?? '',
      controller: controller,
      disableAutoFillHints: false,
      initialCountryCode: 'EG',
      languageCode:
          AppRouter
                  .router
                  .configuration
                  .navigatorKey
                  .currentContext
                  ?.isArabic ??
              false
          ? 'ar'
          : 'en',
      onChanged: (phone) {
        logger(phone.completeNumber); // للـ debugging
        if (onPhoneChanged != null) {
          onPhoneChanged!(phone.completeNumber); // تمرير الرقم الكامل
        }
      },
      onCountryChanged: (country) {
        logger('Country changed to: ${country.name}');
        if (controller != null) {
          controller!.clear(); // تنظيف الـ controller عند تغيير البلد
        }
      },
    );
  }
}
