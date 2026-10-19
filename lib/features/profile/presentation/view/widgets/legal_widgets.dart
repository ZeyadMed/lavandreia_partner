import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// شريط صغير فوق الصفحات النصية فيه تاريخ آخر تحديث للنص
/// مشترك بين الشروط والأحكام وسياسة الخصوصية عشان يبقوا نفس الشكل
class LastUpdatedBanner extends StatelessWidget {
  /// النص بعد الترجمة، لأن تاريخ سياسة الخصوصية بييجي من السيرفر
  final String text;

  const LastUpdatedBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18.sp, color: AppColors.primaryColor),
          Gap(10.w),
          Expanded(
            child: Label(
              text: text,
              maxLines: 2,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// الكارت الأبيض اللي المحتوى بيتعرض جواه في الصفحات النصية
class LegalCard extends StatelessWidget {
  final Widget child;

  const LegalCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
