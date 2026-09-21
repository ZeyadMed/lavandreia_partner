import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_timeline.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/update_status_sheet.dart';

/// صفحة تفاصيل الطلب
/// بترجع الطلب بعد التعديل لما المستخدم يرجع، عشان الليستة تحدّث نفسها
class OrderDetailsScreen extends StatefulWidget {
  final PartnerOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late PartnerOrder _order = widget.order;

  Future<void> _updateStatus() async {
    final newStage = await showUpdateStatusSheet(
      context: context,
      currentStage: _order.stage,
    );
    if (newStage == null || !mounted) return;

    setState(() => _order = _order.copyWithStage(newStage));
  }

  @override
  Widget build(BuildContext context) {
    // آخر مرحلة يبقى مفيش حاجة نحدّثها بعدها
    final canUpdate = _order.stage.next != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_order);
      },
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        body: Column(
          children: [
            _DetailsHeader(order: _order),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  children: [
                    CustomerInfoCard(order: _order),
                    Gap(14.h),
                    OrderItemsCard(order: _order),
                    Gap(14.h),
                    OrderMetaCard(order: _order),
                    Gap(14.h),
                    DetailsCard(
                      titleKey: 'order_stages',
                      child: OrderTimeline(currentStage: _order.stage),
                    ),
                    Gap(20.h),
                    if (canUpdate)
                      CustomButton(
                        title: 'update_status',
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        onPressed: _updateStatus,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الهيدر الأزرق: رقم الطلب وشيب الحالة وزرار الرجوع
class _DetailsHeader extends StatelessWidget {
  final PartnerOrder order;

  const _DetailsHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16.w,
        MediaQuery.of(context).padding.top + 12.h,
        16.w,
        18.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // زرار الرجوع، السهم بيشاور ناحية الرجوع حسب اتجاه اللغة
          // في العربي على اليمين وفي الإنجليزي على الشمال
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Directionality.of(context) == TextDirection.ltr
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_new_rounded,
                size: 15.sp,
                color: AppColors.whiteColor,
              ),
            ),
          ),
          Gap(12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Label(
                text: order.displayNumber,
                maxLines: 1,
                style: TextStyles.whiteText(19, weight: FontWeight.w800),
              ),
              Gap(8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: order.status.backgroundColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: LocalizedLabel(
                  text: order.status.labelKey,
                  maxLines: 1,
                  style: TextStyles.boldStyle(
                    12,
                    color: order.status.foregroundColor,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
