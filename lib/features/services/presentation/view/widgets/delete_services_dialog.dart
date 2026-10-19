import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';

/// تأكيد حذف الأصناف، بنفس شكل ديالوج تسجيل الخروج
/// لو صنف واحد بيظهر اسمه، ولو أكتر بيظهر عددهم
/// بيرجّع true لو اليوزر أكّد، و null/false لو رجع
Future<bool?> showDeleteServicesDialog(
  BuildContext context,
  List<MyServiceItem> items,
) {
  final isSingle = items.length == 1;
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
              color: AppColors.redColor2.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 26.sp,
              color: AppColors.redColor2,
            ),
          ),
          Gap(16.h),
          LocalizedLabel(
            text: isSingle ? 'delete_service_item' : 'delete_services',
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18, weight: FontWeight.w800),
          ),
          Gap(8.h),
          Label(
            text: isSingle
                ? 'delete_service_item_confirm'.tr(
                    args: [items.single.serviceItemName],
                  )
                : 'delete_services_confirm'.plural(items.length),
            textAlign: TextAlign.center,
            maxLines: 4,
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
                labelKey: 'cancel',
                background: AppColors.semiWhiteColor3,
                textColor: AppColors.darkTextColor,
                onTap: () => Navigator.of(dialogContext).pop(false),
              ),
            ),
            Gap(10.w),
            Expanded(
              child: _DialogButton(
                labelKey: 'delete',
                background: AppColors.redColor2,
                textColor: AppColors.whiteColor,
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
