import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/services/data/models/laundry_service.dart';

/// كارت الخدمة الواحدة: الأيقونة والاسم والسعر، وزرار التعديل والسويتش
/// الخدمة الموقوفة بتبهت كلها عشان تبان إنها مش شغالة
class ServiceCard extends StatelessWidget {
  final LaundryService service;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // الشفافية على الكارت كله بدل ما نلوّن كل عنصر لوحده
      child: Opacity(
        opacity: isActive ? 1 : 0.45,
        child: Row(
          children: [
            _ServiceIcon(emoji: service.emoji),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedLabel(
                    text: service.labelKey,
                    maxLines: 1,
                    style: TextStyles.boldStyle(15, weight: FontWeight.w700),
                  ),
                  Gap(4.h),
                  Label(
                    text: 'service_price_value'.tr(
                      namedArgs: {
                        'price': service.price,
                        'currency': 'currency_sar'.tr(),
                      },
                    ),
                    maxLines: 1,
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.greyColor3,
                    ),
                  ),
                ],
              ),
            ),
            Gap(8.w),
            // التعديل شغال حتى والخدمة موقوفة عشان اليوزر يقدر يظبط
            // السعر قبل ما يفعّلها تاني
            IconButton(
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 34.w, minHeight: 34.w),
              tooltip: 'edit'.tr(),
              icon: Icon(
                Icons.edit_outlined,
                size: 19.sp,
                color: AppColors.greyColor4,
              ),
            ),
            Gap(4.w),
            Switch(
              value: isActive,
              onChanged: onActiveChanged,
              activeThumbColor: AppColors.whiteColor,
              activeTrackColor: AppColors.primaryColor,
              inactiveThumbColor: AppColors.whiteColor,
              inactiveTrackColor: AppColors.semiWhiteColor2,
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// المربع الرمادي الفاتح اللي فيه إيموچي الخدمة
class _ServiceIcon extends StatelessWidget {
  final String emoji;

  const _ServiceIcon({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.semiWhiteColor3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Label(text: emoji, style: TextStyle(fontSize: 20.sp)),
    );
  }
}
