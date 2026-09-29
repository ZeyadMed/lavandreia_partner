import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_card.dart';

/// قسم "آخر الطلبات" في الرئيسية: عنوان ومعاه "عرض الكل" وتحتهم الكروت
class LatestOrdersSection extends StatelessWidget {
  final List<PartnerOrder> orders;

  /// بيودّي المستخدم لتاب الطلبات
  final VoidCallback onViewAll;

  /// بيفتح تفاصيل الطلب اللي اتضغط عليه
  final ValueChanged<PartnerOrder> onOrderTap;

  /// أول تحميل، بيظهر سكيلتون مكان الكروت
  final bool isLoading;

  /// الريكوست فشل ومفيش طلبات قديمة نعرضها
  final bool hasError;

  final VoidCallback? onRetry;

  const LatestOrdersSection({
    super.key,
    required this.orders,
    required this.onViewAll,
    required this.onOrderTap,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LocalizedLabel(
              text: 'latest_orders',
              style: TextStyles.boldStyle(18, weight: FontWeight.w800),
            ),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onViewAll,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: LocalizedLabel(
                  text: 'view_all',
                  style: TextStyles.boldStyle(
                    14,
                    color: AppColors.primaryColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        Gap(14.h),
        if (isLoading && orders.isEmpty)
          ...List.generate(
            3,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: const OrderCardSkeleton(),
            ),
          )
        else if (hasError && orders.isEmpty)
          _SectionMessage(text: 'orders_load_failed', onRetry: onRetry)
        else if (orders.isEmpty)
          const _SectionMessage(text: 'no_orders')
        else
          ...orders.map(
            (order) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: OrderCard(order: order, onTap: () => onOrderTap(order)),
            ),
          ),
      ],
    );
  }
}

/// رسالة مكان الكروت لما مفيش طلبات أو الريكوست فشل
class _SectionMessage extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const _SectionMessage({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48.sp,
              color: AppColors.greyColor5,
            ),
            Gap(8.h),
            LocalizedLabel(
              text: text,
              textAlign: TextAlign.center,
              style: TextStyles.darkRegular14.copyWith(
                color: AppColors.greyColor3,
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
                label: LocalizedLabel(
                  text: 'try_again',
                  style: TextStyles.darkBold14.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
