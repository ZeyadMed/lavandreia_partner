import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_phone_field.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController phoneController = TextEditingController();

  /// الرقم كامل بكود الدولة (+218911234567)، بيتحدث مع كل تغيير في الحقل
  /// ده اللي بيتبعتله كود التحقق، مش نص الكنترولر اللي بيبقى الرقم المحلي بس
  String completePhone = '';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
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
              Gap(40.h),
              // Header
              LocalizedLabel(
                text: "forgot_password_title",
                style: TextStyles.blackBold20,
              ),

              Gap(10.h),

              // Body description
              LocalizedLabel(
                text: "forgot_password_desc",
                maxLines: 3,
                style: TextStyles.blackRegular16.copyWith(
                  color: AppColors.lightTextColor,
                ),
              ),

              Gap(40.h),

              // Phone Field
              CustomPhoneField(
                controller: phoneController,
                onChanged: (phone) => completePhone = phone.completeNumber,
              ),

              Gap(30.h),

              // Reset Password Button
              CustomButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.push(AppRouter.verifyOtp);
                  }
                },
                title: "reset_password".tr(),
              ),

              Gap(20.h),

              // Back to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRouter.login),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14.sp,
                          color: AppColors.primaryColor,
                        ),
                        Gap(4.w),
                        LocalizedLabel(
                          text: "back_to_login",
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
      ),
    );
  }
}
