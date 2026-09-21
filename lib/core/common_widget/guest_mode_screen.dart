import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class GuestModeScreen extends StatelessWidget {
  const GuestModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "cart".tr()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(Assets.assetsImagesLogo, height: 200, width: 200),
              Gap(20.h),
              Text(
                "guestMode".tr(),
                style: TextStyles.darkBold18,
                textAlign: TextAlign.center,
              ),
              Gap(20.h),
              GestureDetector(
                onTap: () {
                  GoRouter.of(context).go(AppRouter.login);
                },
                child: Text(
                  "login".tr(),
                  style: TextStyles.darkRegular18.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
