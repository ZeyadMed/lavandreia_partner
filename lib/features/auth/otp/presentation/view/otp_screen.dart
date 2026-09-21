import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/common_widget/otp_text_field.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _pinController = TextEditingController();

  static const int _countdownSeconds = 60;
  int _secondsRemaining = 0;
  bool _canResend = true;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _secondsRemaining = _countdownSeconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              Assets.assetsImagesLogo,
              width: double.infinity,
              height: context.screenHeight * 0.2,
              color: AppColors.blackColor,
            ),
            // Gap(40.h),
            // Header
            LocalizedLabel(text: "otp_title", style: TextStyles.blackBold20),

            Gap(10.h),

            // Description
            LocalizedLabel(
              text: "otp_desc",
              maxLines: 3,
              style: TextStyles.blackRegular16.copyWith(
                color: AppColors.lightTextColor,
              ),
            ),

            Gap(40.h),

            // OTP Field
            OtpTextField(pinController: _pinController),

            Gap(20.h),

            // Countdown / Resend row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalizedLabel(
                  text: "didnt_receive_otp",
                  style: TextStyles.blackRegular16,
                ),
                Gap(6.w),
                _canResend
                    ? GestureDetector(
                        onTap: _startCountdown,
                        child: LocalizedLabel(
                          text: "resend_otp",
                          style: TextStyles.blackBold14.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Text(
                        _formattedTime,
                        style: TextStyles.blackBold14.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ],
            ),

            Gap(30.h),

            // Verify Button
            CustomButton(
              onPressed: () {
                context.go(AppRouter.changePassword);
              },
              title: "verify_otp".tr(),
            ),

            Gap(20.h),

            // Back to previous screen
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                      Gap(4.w),
                      LocalizedLabel(
                        text: "back",
                        style: TextStyles.blackBold14.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
