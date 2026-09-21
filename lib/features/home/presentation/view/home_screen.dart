import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/router/bottom_nav_controller.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/features/home/presentation/view/widgets/home_header.dart';
import 'package:lavanderia_partner/features/home/presentation/view/widgets/home_stats_row.dart';
import 'package:lavanderia_partner/features/home/presentation/view/widgets/latest_orders_section.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_mock_data.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAvailable = true;

  /// مؤقتاً من الداتا الوهمية لحد ما نربط الـ API
  final List<PartnerOrder> _latestOrders = OrdersMockData.latest;

  /// بيفتح التفاصيل وبيحدّث الكارت لو الحالة اتغيرت جوه
  Future<void> _openDetails(PartnerOrder order) async {
    final updated = await Navigator.of(context).push<PartnerOrder>(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
    );
    if (updated == null || !mounted) return;

    setState(() {
      final index = _latestOrders.indexWhere((o) => o.number == updated.number);
      if (index != -1) _latestOrders[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      body: Column(
        children: [
          HomeHeader(
            // مؤقتاً لحد ما نربط بيانات المغسلة من الـ API
            laundryName: 'مغسلة المدينة',
            isAvailable: isAvailable,
            onAvailabilityChanged: (value) {
              setState(() => isAvailable = value);
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeStatsRow(
                    completedToday: OrdersMockData.completedTodayCount,
                    inProgress: OrdersMockData.inProgressCount,
                    newOrders: OrdersMockData.newOrdersCount,
                  ),
                  Gap(22.h),
                  LatestOrdersSection(
                    orders: _latestOrders,
                    onViewAll: () =>
                        BottomNavController.instance.goTo(BottomNavTab.orders),
                    onOrderTap: _openDetails,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
