import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/string_extension.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/preparation_time.dart';

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
                      text: order.customerPhone.forceLtr,
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
          // اللي هيسلّم الهدوم للدليفري لو مش العميل نفسه
          if (order.pickupContactName.isNotEmpty &&
              order.pickupContactName != order.customerName) ...[
            Gap(12.h),
            Row(
              children: [
                LocalizedLabel(
                  text: 'pickup_contact',
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.greyColor4,
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: Label(
                    text: [
                      order.pickupContactName,
                      order.pickupContactPhone.forceLtr,
                    ].where((text) => text.isNotEmpty).join(' • '),
                    maxLines: 1,
                    style: TextStyles.darkBold14.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          // الرسوم مش بتيجي في كل الطلبات، فبنعرض التفاصيل بس لو موجودة
          if (order.pickupFee > 0 || order.dropoffFee > 0) ...[
            _PriceRow(labelKey: 'items_total', amount: order.itemsTotal),
            _PriceRow(labelKey: 'pickup_fee', amount: order.pickupFee),
            _PriceRow(labelKey: 'dropoff_fee', amount: order.dropoffFee),
            Gap(4.h),
          ],
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
              // طلبات السيرفر مش بترجّع نوع الخدمة
              if (item.serviceKey.isNotEmpty) ...[
                Gap(2.h),
                LocalizedLabel(
                  text: item.serviceKey,
                  maxLines: 1,
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.greyColor4,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Label(
                text: '× ${item.quantity}',
                maxLines: 1,
                style: TextStyles.darkBold14.copyWith(
                  color: AppColors.greyColor2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.lineTotal > 0) ...[
                Gap(2.h),
                // القطعة اللي هترجع سعرها اتشال من الإجمالي
                Label(
                  text: formatAmount(item.lineTotal),
                  maxLines: 1,
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.greyColor4,
                    decoration: item.isReturned
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
              if (item.isReturned) ...[Gap(4.h), const _ReturnedChip()],
            ],
          ),
        ],
      ),
    );
  }
}

/// شيب "هترجع للعميل" على القطعة اللي العميل رفض تعديلها
class _ReturnedChip extends StatelessWidget {
  const _ReturnedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xffFCE8E8),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: LocalizedLabel(
        text: 'item_returned',
        maxLines: 1,
        style: TextStyles.boldStyle(
          11,
          color: AppColors.redColor2,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// سطر "اسم الرسوم ... المبلغ" فوق الإجمالي
class _PriceRow extends StatelessWidget {
  final String labelKey;
  final double amount;

  const _PriceRow({required this.labelKey, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
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
            text: formatAmount(amount),
            maxLines: 1,
            style: TextStyles.darkBold14.copyWith(fontWeight: FontWeight.w600),
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
    final locale = Localizations.localeOf(context).languageCode;
    final prepMinutes = order.preparationDurationMinutes;
    final readyAt = order.promisedReadyAt;
    // المسافة ووقت التسليم مش جايين من السيرفر لسه، فبنخفيهم لو صفر
    // الدفع بيتطلب بعد المطابقة بس، وقبلها ملوش حالة
    final rows = <({String labelKey, Widget value})>[
      (labelKey: 'order_number', value: _MetaValue(order.displayNumber)),
      (labelKey: 'order_time', value: _MetaValue(order.displayDate(locale))),
      if (order.distanceKm > 0)
        (labelKey: 'distance', value: _MetaValue(order.displayDistance)),
      if (order.estimatedHours > 0)
        (labelKey: 'estimated_delivery', value: _MetaValue(order.displayEta)),
      if (prepMinutes != null)
        (
          labelKey: 'preparation_duration',
          value: _MetaValue(formatPreparationDuration(prepMinutes)),
        ),
      // موعد الجاهزية بييجي بعد ما المغسلة تأكّد الاستلام بس
      if (readyAt != null)
        (
          labelKey: 'promised_ready_at',
          value: _MetaValue(formatReadyAt(readyAt, locale)),
        ),
      if (order.isPreparing)
        (labelKey: 'time_remaining', value: ReadyCountdownText(order: order)),
      if (order.paymentStatus != PaymentStatus.none)
        (
          labelKey: 'payment_status',
          value: _MetaValue(order.paymentStatus.labelKey.tr()),
        ),
    ];

    return DetailsCard(
      titleKey: 'order_info',
      child: Column(
        children: [
          for (final (index, row) in rows.indexed)
            _MetaRow(
              labelKey: row.labelKey,
              value: row.value,
              showDivider: index < rows.length - 1,
            ),
        ],
      ),
    );
  }
}

/// العدّاد التنازلي لموعد الجاهزية، وبيقلب أحمر "متأخر" لما الموعد يعدّي
class ReadyCountdownText extends StatelessWidget {
  final PartnerOrder order;
  final double fontSize;

  const ReadyCountdownText({super.key, required this.order, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final readyAt = order.promisedReadyAt;
    if (readyAt == null) return const SizedBox.shrink();
    return CountdownBuilder(
      target: readyAt,
      builder: (context, remaining) {
        final isLate = remaining.isNegative;
        return Label(
          text: (isLate ? 'overdue_by' : 'ready_in').tr(
            args: [formatCountdown(remaining)],
          ),
          maxLines: 1,
          style: TextStyles.boldStyle(
            fontSize,
            color: isLate ? AppColors.redColor2 : AppColors.primaryColor,
            weight: FontWeight.w700,
          ),
        );
      },
    );
  }
}

/// قيمة نصية عادية في سطر من كارت معلومات الطلب
class _MetaValue extends StatelessWidget {
  final String text;

  const _MetaValue(this.text);

  @override
  Widget build(BuildContext context) {
    return Label(
      text: text,
      maxLines: 1,
      style: TextStyles.darkBold14.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// سطر "اسم الحقل ... القيمة" في كارت معلومات الطلب
class _MetaRow extends StatelessWidget {
  final String labelKey;
  final Widget value;
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
              Gap(12.w),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: value,
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
