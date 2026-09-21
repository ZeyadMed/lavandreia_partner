import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_mock_data.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_card.dart';

/// فلتر التابات اللي فوق في صفحة الطلبات
/// null في [status] معناها تاب "الكل"
class _OrdersFilter {
  final String labelKey;
  final PartnerOrderStatus? status;

  const _OrdersFilter({required this.labelKey, this.status});
}

class OrdersScreen extends StatefulWidget {
  /// التاب اللي الصفحة تفتح عليه، الافتراضي "الكل"
  final PartnerOrderStatus? initialStatus;

  const OrdersScreen({super.key, this.initialStatus});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const List<_OrdersFilter> _filters = [
    _OrdersFilter(labelKey: 'all'),
    _OrdersFilter(
      labelKey: 'orders_tab_new',
      status: PartnerOrderStatus.newOrder,
    ),
    _OrdersFilter(
      labelKey: 'orders_tab_in_progress',
      status: PartnerOrderStatus.inProgress,
    ),
    _OrdersFilter(
      labelKey: 'orders_tab_ready',
      status: PartnerOrderStatus.ready,
    ),
    _OrdersFilter(
      labelKey: 'orders_tab_completed',
      status: PartnerOrderStatus.completed,
    ),
    _OrdersFilter(
      labelKey: 'orders_tab_rejected',
      status: PartnerOrderStatus.rejected,
    ),
  ];

  /// لو الحالة اللي جاية مش موجودة في التابات بنفتح على "الكل"
  late int _selectedIndex = _filters
      .indexWhere((filter) => filter.status == widget.initialStatus)
      .clamp(0, _filters.length - 1);

  /// مؤقتاً من الداتا الوهمية لحد ما نربط الـ API
  final List<PartnerOrder> _orders = OrdersMockData.all;

  /// بيفتح التفاصيل وبيستنى الطلب راجع منها عشان لو الحالة اتغيرت
  /// الليستة تحدّث نفسها فوراً
  Future<void> _openDetails(PartnerOrder order) async {
    final updated = await Navigator.of(context).push<PartnerOrder>(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
    );
    if (updated == null || !mounted) return;

    setState(() {
      final index = _orders.indexWhere((o) => o.number == updated.number);
      if (index != -1) _orders[index] = updated;
    });
  }

  List<PartnerOrder> get _visibleOrders {
    final status = _filters[_selectedIndex].status;
    if (status == null) return _orders;
    return _orders.where((order) => order.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _visibleOrders;

    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      body: Column(
        children: [
          _OrdersHeader(count: _orders.length),
          _OrdersTabsBar(
            filters: _filters,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          Expanded(
            child: orders.isEmpty
                ? const _EmptyOrders()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => Gap(14.h),
                    itemBuilder: (context, index) => OrderCard(
                      order: orders[index],
                      onTap: () => _openDetails(orders[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// الهيدر الأزرق: عنوان الصفحة وتحته إجمالي عدد الطلبات
class _OrdersHeader extends StatelessWidget {
  final int count;

  const _OrdersHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        20.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedLabel(
            text: 'my_orders',
            style: TextStyles.whiteText(22, weight: FontWeight.w800),
          ),
          Gap(4.h),
          Label(
            text: 'orders_total_count'.tr(args: [count.toString()]),
            style: TextStyles.whiteText(
              13,
              weight: FontWeight.w400,
            ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// شريط التابات الأبيض اللي تحت الهيدر
class _OrdersTabsBar extends StatelessWidget {
  final List<_OrdersFilter> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _OrdersTabsBar({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.whiteColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          children: List.generate(filters.length, (index) {
            final isSelected = index == selectedIndex;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      child: LocalizedLabel(
                        text: filters[index].labelKey,
                        maxLines: 1,
                        style: TextStyles.boldStyle(
                          14,
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.greyColor4,
                          weight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    // الخط الأزرق تحت التاب المختار
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(3.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// بيظهر لما التاب المختار مفيهوش طلبات
class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56.sp,
            color: AppColors.greyColor5,
          ),
          Gap(12.h),
          LocalizedLabel(
            text: 'no_orders_in_tab',
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(
              color: AppColors.greyColor3,
            ),
          ),
        ],
      ),
    );
  }
}
