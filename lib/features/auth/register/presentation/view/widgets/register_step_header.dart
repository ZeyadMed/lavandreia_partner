import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// الهيدر الأزرق اللي فوق كل خطوات التسجيل
/// فيه العنوان، رقم الخطوة، زرار الرجوع، وشريط يوضح الخطوات
class RegisterStepHeader extends StatelessWidget {
  /// رقم الخطوة الحالية بادئ من 1
  final int currentStep;

  /// أسماء الخطوات كمفاتيح ترجمة، ترتيبها من الأولى للأخيرة
  final List<String> stepKeys;

  final VoidCallback onBack;

  const RegisterStepHeader({
    super.key,
    required this.currentStep,
    required this.stepKeys,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12.h,
        bottom: 12.h,
        left: 16.w,
        right: 16.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BackButton(onTap: onBack),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedLabel(
                      text: 'create_laundry_account',
                      style: TextStyles.whiteBold15.copyWith(fontSize: 18.sp),
                      textAlign: TextAlign.end,
                    ),
                    Gap(2.h),
                    Label(
                      text: 'step_of'.tr(
                        namedArgs: {
                          'current': '$currentStep',
                          'total': '${stepKeys.length}',
                        },
                      ),
                      style: TextStyles.whiteBold14.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              Gap(12.w),
            ],
          ),
          Gap(16.h),
          _StepsIndicator(currentStep: currentStep, stepKeys: stepKeys),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(
          // السهم بيلف مع اتجاه اللغة لوحده
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 16.sp,
        ),
      ),
    );
  }
}

/// شريط الخطوات: خط فوق واسم الخطوة تحته
/// الخطوة الحالية والخطوات اللي فاتت بيبقوا واضحين، واللي جاي باهت
class _StepsIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> stepKeys;

  const _StepsIndicator({required this.currentStep, required this.stepKeys});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepKeys.length, (index) {
        final stepNumber = index + 1;
        final isCurrent = stepNumber == currentStep;
        final isDone = stepNumber < currentStep;
        final isActive = isCurrent || isDone;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Column(
              children: [
                Container(
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Gap(6.h),
                LocalizedLabel(
                  text: stepKeys[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyles.whiteBold14.copyWith(
                    fontSize: 10.sp,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w300,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
