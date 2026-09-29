import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/router/bottom_nav_controller.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/features/home/presentation/view/widgets/home_header.dart';
import 'package:lavanderia_partner/features/home/presentation/view/widgets/home_stats_row.dart';
import 'package:lavanderia_partner/features/home/presentation/view/widgets/latest_orders_section.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/data/orders_mock_data.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';
import 'package:lavanderia_partner/features/profile/data/profile_data_source.dart';
import 'package:lavanderia_partner/features/profile/presentation/view_model/profile_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// اسم المغسلة وصورتها وعنوانها للهيدر
  final ProfileCubit _profileCubit = ProfileCubit(getIt<ProfileDataSource>())
    ..fetchDataMap();

  /// آخر 3 طلبات بس، فمن غير سكرول ولا صفحات تانية
  final OrdersCubit _ordersCubit = OrdersCubit(
    getIt<OrdersDataSource>(),
    pageSize: 3,
  )..fetch(page: 1);

  @override
  void dispose() {
    _profileCubit.close();
    _ordersCubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_profileCubit.fetchDataMap(), _ordersCubit.refresh()]);
  }

  /// الكارت بيتحدث لوحده من [OrdersCubit.changes] لو الطلب اتعدل جوه
  void _openDetails(PartnerOrder order) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      body: Column(
        children: [
          BlocBuilder<ProfileCubit, BaseState<PartnerProfile>>(
            bloc: _profileCubit,
            // بنحتفظ بالبيانات القديمة وهي بتتحدث عشان الهيدر مايرجعش فاضي
            buildWhen: (previous, current) => current.data != null,
            builder: (context, state) => HomeHeader(profile: state.data),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    BlocBuilder<OrdersCubit, BaseState<PartnerOrder>>(
                      bloc: _ordersCubit,
                      builder: (context, state) => LatestOrdersSection(
                        orders: state.items,
                        isLoading: state.isInitial || state.isLoading,
                        hasError: state.isFailure,
                        onRetry: _ordersCubit.refresh,
                        onViewAll: () => BottomNavController.instance.goTo(
                          BottomNavTab.orders,
                        ),
                        onOrderTap: _openDetails,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
