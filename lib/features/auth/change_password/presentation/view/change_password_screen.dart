import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/helpers/validators.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
                text: "change_password_title",
                style: TextStyles.blackBold32,
              ),

              Gap(10.h),

              // Description
              LocalizedLabel(
                text: "change_password_desc",
                maxLines: 3,
                style: TextStyles.blackRegular16.copyWith(
                  color: AppColors.lightTextColor,
                ),
              ),

              Gap(40.h),

              // New Password Field
              Customtextfield(
                textEditingController: _newPasswordController,
                hintText: 'new_password'.tr(),
                keyboardType: TextInputType.visiblePassword,
                prefix: const Icon(Icons.lock_outlined),
                validator: Validators.passwordValidator,
                obscureText: _obscureNewPassword,
                suffix: IconButton(
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),

              Gap(10.h),

              // Confirm New Password Field
              Customtextfield(
                textEditingController: _confirmPasswordController,
                hintText: 'confirm_new_password'.tr(),
                keyboardType: TextInputType.visiblePassword,
                prefix: const Icon(Icons.lock_outlined),
                validator: (value) => Validators.repeatPasswordValidator(
                  value: value,
                  Password: _newPasswordController.text,
                ),
                obscureText: _obscureConfirmPassword,
                suffix: IconButton(
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),

              Gap(30.h),

              // Change Password Button
              CustomButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.go(AppRouter.login);
                  }
                },
                title: "change_password_btn".tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
