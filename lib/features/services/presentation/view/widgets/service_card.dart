import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/flexiable_image.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';

/// كارت صنف واحد: الصورة والاسم والسعر وزرار التعديل
/// في وضع التحديد زرار التعديل بيتبدل بتشيك بوكس، والضغط على الكارت بيحدده
class ServiceCard extends StatelessWidget {
  final MyServiceItem item;

  /// السعر اللي بيتعرض، ممكن يكون متعدّل ولسه متحفظش
  final double price;
  final bool isEdited;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ServiceCard({
    super.key,
    required this.item,
    required this.price,
    required this.isEdited,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onEdit,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withValues(alpha: 0.06)
              : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _ItemImage(imageUrl: item.serviceItemImageUrl),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    text: item.serviceItemName,
                    maxLines: 1,
                    style: TextStyles.boldStyle(15, weight: FontWeight.w700),
                  ),
                  Gap(4.h),
                  Label(
                    text: 'service_price_value'.tr(
                      namedArgs: {
                        'price': formatPrice(price),
                        'currency': 'currency'.tr(),
                      },
                    ),
                    maxLines: 1,
                    // السعر المتعدّل بيتلوّن عشان اليوزر يعرف إنه لسه متحفظش
                    style: TextStyles.darkRegular12.copyWith(
                      color: isEdited
                          ? AppColors.primaryColor
                          : AppColors.greyColor3,
                      fontWeight: isEdited ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            Gap(8.w),
            if (isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
              )
            else
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
          ],
        ),
      ),
    );
  }
}

/// صورة الصنف، ولو مفيش صورة بيظهر مربع رمادي فيه أيقونة
class _ItemImage extends StatelessWidget {
  final String? imageUrl;

  const _ItemImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 44.w,
      height: 44.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.semiWhiteColor3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.local_laundry_service_outlined,
        size: 22.sp,
        color: AppColors.primaryColor,
      ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return placeholder;

    return FlexibleImage(
      source: url,
      width: 44.w,
      height: 44.w,
      borderRadius: 12.r,
      placeholder: placeholder,
    );
  }
}
