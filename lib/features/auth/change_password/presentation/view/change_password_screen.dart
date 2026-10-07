import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/common_widget/loading_button.dart';
import 'package:lavanderia_partner/core/common_widget/otp_text_field.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/helpers/validators.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';
import 'package:lavanderia_partner/features/auth/forget_password/data/forget_password_data_source.dart';

/// آخر خطوة في نسيت كلمة المرور: الكود اللي وصل مع كلمة المرور الجديدة
/// في ريكوست واحد، من غير صفحة verify otp قبلها
class ChangePasswordScreen extends StatefulWidget {
  /// الرقم اللي اتبعتله الكود من صفحة نسيت كلمة المرور
  final String phoneNumber;

  const ChangePasswordScreen({super.key, required this.phoneNumber});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();
  bool _isResetting = false;

  /// نفس طول خانات [OtpTextField]
  static const int _codeLength = 6;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_isResetting) return;

    final code = _codeController.text.trim();
    // الكود مش جوه الـ Form، فبنتشيك عليه لوحده
    final isCodeComplete = code.length >= _codeLength;
    final isFormValid = _formKey.currentState!.validate();
    if (!isCodeComplete) {
      context.showErrorMessage('otp_incomplete'.tr());
      return;
    }
    if (!isFormValid) return;

    setState(() => _isResetting = true);

    final result = await getIt<ForgetPasswordDataSource>().resetPassword(
      phoneNumber: widget.phoneNumber,
      code: code,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isResetting = false);

    result.fold(
      (failure) {
        // الكود الغلط بيرجع برسالة السيرفر، أما أخطاء الاتصال فالـ ApiConsumer
        // هو اللي بيعرضها
        if (failure is ServerFailure ||
            failure is UnknownFailure ||
            failure is ParsingFailure ||
            failure is VerifyOTPFailure) {
          context.showErrorMessage(failure.message);
        }
      },
      (_) {
        context.showSuccessMessage('password_reset_success'.tr());
        // go عشان صفحات نسيت كلمة المرور تتشال من الـ stack
        context.go(AppRouter.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      // سكرول عشان خانات الكود وكلمة المرور ماتتغطاش لما الكيبورد يفتح
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                Gap(30.h),

                // Code Field
                OtpTextField(pinController: _codeController),

                Gap(20.h),

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
                      setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      );
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
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
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
                _isResetting
                    ? const Center(child: LoadingButton())
                    : CustomButton(
                        onPressed: _resetPassword,
                        title: "change_password_btn".tr(),
                      ),

                Gap(20.h),

                // Back to the phone step to request a new code
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
          ),
        ),
      ),
    );
  }
}
