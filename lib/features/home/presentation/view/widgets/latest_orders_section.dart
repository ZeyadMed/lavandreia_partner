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

  const LatestOrdersSection({
    super.key,
    required this.orders,
    required this.onViewAll,
    required this.onOrderTap,
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
