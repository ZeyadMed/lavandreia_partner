import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';

/// كارت الطلب الواحد، نفسه في الرئيسية وفي صفحة الطلبات
class OrderCard extends StatelessWidget {
  final PartnerOrder order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر الأول: شيب الحالة على الشمال ورقم الطلب على اليمين
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(status: order.status),
                // const Spacer(),
                Flexible(
                  child: Label(
                    text: order.displayNumber,
                    maxLines: 1,
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.greyColor4,
                    ),
                  ),
                ),
              ],
            ),
            Gap(6.h),
            Label(
              text: order.customerName,
              maxLines: 1,
              style: TextStyles.boldStyle(17, weight: FontWeight.w800),
            ),
            Gap(12.h),
            // شيبات القطع، بتلف لسطر تاني لو كتير
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: order.items
                  .map((item) => _ItemChip(text: item.display))
                  .toList(),
            ),
            Gap(14.h),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            Gap(12.h),
            // السعر على الشمال والعنوان على اليمين
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Label(
                  text: order.displayTotal,
                  maxLines: 1,
                  style: TextStyles.boldStyle(
                    16,
                    color: AppColors.primaryColor,
                    weight: FontWeight.w800,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MetaRow(
                        icon: Icons.location_on,
                        iconColor: AppColors.redColor2,
                        text: order.address,
                      ),
                      Gap(8.h),
                      _MetaRow(
                        icon: Icons.access_time_rounded,
                        iconColor: AppColors.greyColor4,
                        text: order.displayDate(context.locale.languageCode),
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

/// شيب حالة الطلب اللي فوق يسار الكارت
class _StatusChip extends StatelessWidget {
  final PartnerOrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: LocalizedLabel(
        text: status.labelKey,
        maxLines: 1,
        style: TextStyles.boldStyle(
          12,
          color: status.foregroundColor,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// شيب القطعة الرمادي الصغير
class _ItemChip extends StatelessWidget {
  final String text;

  const _ItemChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.semiWhiteColor3,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Label(
        text: text,
        maxLines: 1,
        style: TextStyles.darkRegular12.copyWith(
          color: AppColors.greyColor2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// سطر أيقونة + نص زي العنوان والوقت تحت في الكارت
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _MetaRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Label(
            text: text,
            maxLines: 1,
            textAlign: TextAlign.end,
            style: TextStyles.darkRegular12.copyWith(
              color: AppColors.greyColor2,
            ),
          ),
        ),
        Gap(6.w),
        Icon(icon, size: 14.sp, color: iconColor),
      ],
    );
  }
}
