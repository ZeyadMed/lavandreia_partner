import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// تأكيد الخروج من صفحة فيها تعديلات لسه ماتحفظتش
/// بيرجّع true لو اليوزر اختار يخرج من غير حفظ، و null/false لو فضل في الصفحة
Future<bool?> showDiscardChangesDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      contentPadding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_calendar_outlined,
              size: 26.sp,
              color: AppColors.primaryColor,
            ),
          ),
          Gap(16.h),
          LocalizedLabel(
            text: 'unsaved_changes',
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18, weight: FontWeight.w800),
          ),
          Gap(8.h),
          LocalizedLabel(
            text: 'unsaved_working_hours_message',
            textAlign: TextAlign.center,
            maxLines: 3,
            style: TextStyles.darkRegular14.copyWith(
              color: AppColors.greyColor3,
            ),
          ),
        ],
      ),
      actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      actions: [
        Row(
          children: [
            Expanded(
              child: _DialogButton(
                labelKey: 'stay',
                background: AppColors.primaryColor,
                textColor: AppColors.whiteColor,
                onTap: () => Navigator.of(dialogContext).pop(false),
              ),
            ),
            Gap(10.w),
            Expanded(
              child: _DialogButton(
                labelKey: 'leave_without_saving',
                background: AppColors.semiWhiteColor3,
                textColor: AppColors.redColor2,
                onTap: () => Navigator.of(dialogContext).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DialogButton extends StatelessWidget {
  final String labelKey;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const _DialogButton({
    required this.labelKey,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: LocalizedLabel(
          text: labelKey,
          textAlign: TextAlign.center,
          style: TextStyles.boldStyle(
            15,
            color: textColor,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
