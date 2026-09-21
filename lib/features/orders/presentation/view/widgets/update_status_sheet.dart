import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';

/// بوتوم شيت اختيار المرحلة الجديدة للطلب
/// بيرجّع المرحلة اللي اتختارت، أو null لو اتقفل من غير اختيار
Future<PartnerOrderStage?> showUpdateStatusSheet({
  required BuildContext context,
  required PartnerOrderStage currentStage,
}) {
  return showModalBottomSheet<PartnerOrderStage>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _UpdateStatusSheet(currentStage: currentStage),
  );
}

class _UpdateStatusSheet extends StatelessWidget {
  final PartnerOrderStage currentStage;

  const _UpdateStatusSheet({required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final stages = PartnerOrderStage.values;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // المقبض الرمادي الصغير فوق
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.semiWhiteColor2,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Gap(18.h),
          LocalizedLabel(
            text: 'update_status',
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18, weight: FontWeight.w800),
          ),
          Gap(6.h),
          LocalizedLabel(
            text: 'update_status_hint',
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular12.copyWith(
              color: AppColors.greyColor4,
            ),
          ),
          Gap(18.h),
          ...stages.map((stage) {
            final isCurrent = stage == currentStage;
            // المراحل اللي فاتت مينفعش نرجعلها
            final isPast = stage.index < currentStage.index;

            return _StageTile(
              stage: stage,
              isCurrent: isCurrent,
              isDisabled: isPast,
              onTap: isPast || isCurrent
                  ? null
                  : () => Navigator.of(context).pop(stage),
            );
          }),
        ],
      ),
    );
  }
}

/// اختيار مرحلة واحدة في البوتوم شيت
class _StageTile extends StatelessWidget {
  final PartnerOrderStage stage;
  final bool isCurrent;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _StageTile({
    required this.stage,
    required this.isCurrent,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = isCurrent
        ? AppColors.filledColor
        : Colors.transparent;
    final Color textColor = isDisabled
        ? AppColors.greyColor5
        : AppColors.darkTextColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isCurrent
                ? AppColors.primaryColor
                : AppColors.semiWhiteColor2,
          ),
        ),
        child: Row(
          children: [
            if (isCurrent)
              LocalizedLabel(
                text: 'current_stage',
                style: TextStyles.boldStyle(
                  11,
                  color: AppColors.primaryColor,
                  weight: FontWeight.w700,
                ),
              )
            else if (isDisabled)
              Icon(Icons.check, size: 16.sp, color: AppColors.greyColor5),
            const Spacer(),
            LocalizedLabel(
              text: stage.labelKey,
              style: TextStyles.boldStyle(
                14,
                color: textColor,
                weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
