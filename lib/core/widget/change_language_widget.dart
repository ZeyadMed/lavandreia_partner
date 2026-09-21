import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class ChangeLanguageWidget extends StatelessWidget {
  const ChangeLanguageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // determine current language: true means Arabic
    final bool isArabic = context.locale.languageCode == 'ar';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5.r),
          bottomRight: Radius.circular(5.r),
        ),
        border: Border(bottom: BorderSide(width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            // show current language name (localized)
            isArabic ? 'language_arabic'.tr() : 'language_english'.tr(),
            style: TextStyles.darkBold16.copyWith(fontWeight: FontWeight.w600),
          ),
          // use EasyLocalization to switch locale between Arabic and English
          CupertinoSwitch(
            value: isArabic,
            activeColor: AppColors.primaryColor,
            onChanged: (val) {
              context.go(AppRouter.initialRoot);
              context.setLocale(Locale(val ? 'ar' : 'en'));
            },
          ),
        ],
      ),
    );
  }
}
