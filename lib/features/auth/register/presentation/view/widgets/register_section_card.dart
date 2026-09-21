import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// الكارت الأبيض اللي بيلف محتوى كل قسم في خطوات التسجيل
class RegisterSectionCard extends StatelessWidget {
  /// مفتاح ترجمة العنوان، ولو null الكارت بيبقى من غير عنوان
  final String? titleKey;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const RegisterSectionCard({
    super.key,
    this.titleKey,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleKey != null) ...[
            LocalizedLabel(text: titleKey!, style: TextStyles.blackBold16),
            Gap(14.h),
          ],
          child,
        ],
      ),
    );
  }
}

/// سطر "المفتاح: القيمة" اللي بيتعرض في شاشة المراجعة
class ReviewRow extends StatelessWidget {
  /// مفتاح ترجمة اسم الحقل
  final String labelKey;

  /// القيمة زي ما اليوزر دخلها، نص جاهز مش مفتاح ترجمة
  final String value;

  /// آخر سطر في الكارت مابيتحطش تحته خط
  final bool showDivider;

  const ReviewRow({
    super.key,
    required this.labelKey,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedLabel(
                text: labelKey,
                style: TextStyles.darkRegular14.copyWith(
                  color: AppColors.greyColor3,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Label(
                  text: value.isEmpty ? '—' : value,
                  textAlign: TextAlign.end,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.darkBold14,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.18)),
      ],
    );
  }
}
