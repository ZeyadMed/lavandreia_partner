import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';

/// الكارت الأبيض اللي بيلف كل قسم في صفحة التفاصيل
class DetailsCard extends StatelessWidget {
  /// مفتاح ترجمة عنوان القسم
  final String titleKey;
  final Widget child;

  const DetailsCard({super.key, required this.titleKey, required this.child});

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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocalizedLabel(
            text: titleKey,
            style: TextStyles.boldStyle(16, weight: FontWeight.w800),
          ),
          Gap(14.h),
          child,
        ],
      ),
    );
  }
}

/// كارت بيانات العميل: الاسم والتليفون والأفاتار وتحتهم العنوان
class CustomerInfoCard extends StatelessWidget {
  final PartnerOrder order;

  const CustomerInfoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      titleKey: 'customer_info',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.whiteColor,
                  size: 24.sp,
                ),
              ),
              Gap(12.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Label(
                      text: order.customerName,
                      maxLines: 1,
                      style: TextStyles.boldStyle(16, weight: FontWeight.w700),
                    ),
                    Gap(4.h),
                    Label(
                      text: order.customerPhone,
                      maxLines: 1,
                      style: TextStyles.darkRegular12.copyWith(
                        color: AppColors.greyColor4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(14.h),
          // شريط العنوان الرمادي
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.semiWhiteColor3,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16.sp,
                  color: AppColors.redColor2,
                ),
                Gap(8.w),
                Expanded(
                  child: Label(
                    text: order.address,
                    maxLines: 2,
                    textAlign: TextAlign.start,
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.greyColor2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// كارت الملابس: كل قطعة بصورتها ونوع الخدمة والكمية، وتحتهم الإجمالي
class OrderItemsCard extends StatelessWidget {
  final PartnerOrder order;

  const OrderItemsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      titleKey: 'clothes',
      child: Column(
        children: [
          ...order.items.map((item) => _ItemRow(item: item)),
          Gap(6.h),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
          Gap(12.h),
          Row(
            children: [
              LocalizedLabel(
                text: 'total',
                style: TextStyles.boldStyle(15, weight: FontWeight.w700),
              ),
              const Spacer(),
              Label(
                text: order.displayTotal,
                maxLines: 1,
                style: TextStyles.boldStyle(
                  18,
                  color: AppColors.primaryColor,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// سطر القطعة الواحدة: الكمية على الشمال، الاسم والخدمة والصورة على اليمين
class _ItemRow extends StatelessWidget {
  final PartnerOrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          ItemImage(imageUrl: item.imageUrl),
          Gap(12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Label(
                text: item.name,
                maxLines: 1,
                style: TextStyles.boldStyle(15, weight: FontWeight.w700),
              ),
              Gap(2.h),
              LocalizedLabel(
                text: item.serviceKey,
                maxLines: 1,
                style: TextStyles.darkRegular12.copyWith(
                  color: AppColors.greyColor4,
                ),
              ),
            ],
          ),
          const Spacer(),
          Label(
            text: '× ${item.quantity}',
            maxLines: 1,
            style: TextStyles.darkBold14.copyWith(
              color: AppColors.greyColor2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// صورة القطعة، بتحمّل من النت وبتتخزن كاش
/// لو اللينك فاضي أو الصورة فشلت بيظهر أيقونة بدالها
class ItemImage extends StatelessWidget {
  final String imageUrl;

  const ItemImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 44.w,
        height: 44.w,
        child: imageUrl.isEmpty
            ? const _ImageFallback()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: AppColors.semiWhiteColor3),
                errorWidget: (_, _, _) => const _ImageFallback(),
              ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.semiWhiteColor3,
      child: Icon(
        Icons.checkroom_rounded,
        size: 22.sp,
        color: AppColors.greyColor5,
      ),
    );
  }
}

/// كارت معلومات الطلب: رقمه ووقته والمسافة ووقت التسليم المتوقع
class OrderMetaCard extends StatelessWidget {
  final PartnerOrder order;

  const OrderMetaCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      titleKey: 'order_info',
      child: Column(
        children: [
          _MetaRow(labelKey: 'order_number', value: order.displayNumber),
          _MetaRow(
            labelKey: 'order_time',
            value: order.displayDate(
              Localizations.localeOf(context).languageCode,
            ),
          ),
          _MetaRow(labelKey: 'distance', value: order.displayDistance),
          _MetaRow(
            labelKey: 'estimated_delivery',
            value: order.displayEta,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

/// سطر "اسم الحقل ... القيمة" في كارت معلومات الطلب
class _MetaRow extends StatelessWidget {
  final String labelKey;
  final String value;
  final bool showDivider;

  const _MetaRow({
    required this.labelKey,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          child: Row(
            children: [
              LocalizedLabel(
                text: labelKey,
                style: TextStyles.darkRegular14.copyWith(
                  color: AppColors.greyColor4,
                ),
              ),
              const Spacer(),
              Label(
                text: value,
                maxLines: 1,
                style: TextStyles.darkBold14.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
      ],
    );
  }
}
