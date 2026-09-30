import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_card.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';

/// فلتر التابات اللي فوق في صفحة الطلبات
/// كل تاب بيجمع كذا حالة، و null في [statuses] معناها تاب "الكل"
/// مفيش تاب للمرفوض لأن السيرفر بيشيله من طلبات المغسلة
class _OrdersFilter {
  final String labelKey;
  final Set<PartnerOrderStatus>? statuses;

  const _OrdersFilter({required this.labelKey, this.statuses});
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
      statuses: {PartnerOrderStatus.newOrder},
    ),
    _OrdersFilter(
      labelKey: 'orders_tab_in_progress',
      statuses: {
        PartnerOrderStatus.awaitingPickup,
        PartnerOrderStatus.atLaundryPendingMatch,
        PartnerOrderStatus.adjustmentPendingApproval,
        PartnerOrderStatus.inProgress,
      },
    ),
    _OrdersFilter(
      labelKey: 'orders_tab_ready',
      statuses: {PartnerOrderStatus.ready, PartnerOrderStatus.outForDelivery},
    ),
    _OrdersFilter(
      labelKey: 'orders_tab_completed',
      statuses: {PartnerOrderStatus.delivered},
    ),
  ];

  /// لو الحالة اللي جاية مش موجودة في التابات بنفتح على "الكل"
  late int _selectedIndex = _indexOf(widget.initialStatus);

  static int _indexOf(PartnerOrderStatus? status) => _filters
      .indexWhere((filter) => filter.statuses?.contains(status) ?? false)
      .clamp(0, _filters.length - 1);

  late final OrdersCubit _cubit = OrdersCubit(getIt<OrdersDataSource>())
    ..initPagination()
    ..fetch(page: 1);

  /// الطلب اللي اتقبل بنفتح له تاب "قيد التنفيذ" عشان اليوزر يلاقيه
  late final StreamSubscription<PartnerOrder> _changesSubscription;

  @override
  void initState() {
    super.initState();
    _changesSubscription = OrdersCubit.changes.listen((order) {
      if (order.status != PartnerOrderStatus.awaitingPickup || !mounted) {
        return;
      }
      setState(() => _selectedIndex = _indexOf(order.status));
    });
  }

  @override
  void dispose() {
    _changesSubscription.cancel();
    _cubit.close();
    super.dispose();
  }

  /// الليستة بتتحدث لوحدها من [OrdersCubit.changes] لو الطلب اتعدل جوه
  void _openDetails(PartnerOrder order) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)));
  }

  /// الفلترة على الطلبات اللي اتحملت بس لأن الـ API مش بياخد الحالة
  List<PartnerOrder> _visibleOrders(List<PartnerOrder> orders) {
    final statuses = _filters[_selectedIndex].statuses;
    if (statuses == null) return orders;
    return orders.where((order) => statuses.contains(order.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      body: BlocBuilder<OrdersCubit, BaseState<PartnerOrder>>(
        bloc: _cubit,
        builder: (context, state) => Column(
          children: [
            _OrdersHeader(count: _cubit.totalCount),
            _OrdersTabsBar(
              filters: _filters,
              selectedIndex: _selectedIndex,
              onSelected: (index) => setState(() => _selectedIndex = index),
            ),
            Expanded(child: _buildList(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BaseState<PartnerOrder> state) {
    // السحب للتحديث بيرجع لـ loading، فبنسيب اللستة القديمة ظاهرة لحد ما الجديدة توصل
    if (state.items.isEmpty) {
      if (state.isFailure) {
        return _EmptyOrders(
          text: 'orders_load_failed',
          onRetry: _cubit.refresh,
        );
      }
      if (!state.isSuccess) return const _OrdersSkeleton();
    }

    final orders = _visibleOrders(state.items);

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: _cubit.refresh,
      child: orders.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                controller: _cubit.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: const _EmptyOrders(),
                ),
              ),
            )
          : ListView.separated(
              controller: _cubit.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              itemCount: orders.length + 1,
              separatorBuilder: (_, _) => Gap(14.h),
              itemBuilder: (context, index) {
                if (index < orders.length) {
                  return OrderCard(
                    order: orders[index],
                    onTap: () => _openDetails(orders[index]),
                  );
                }
                return _ListFooter(
                  state: state,
                  onRetry: () => _cubit.fetch(page: state.page),
                );
              },
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

/// بيظهر لما التاب المختار مفيهوش طلبات أو الريكوست فشل
class _EmptyOrders extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const _EmptyOrders({this.text = 'no_orders_in_tab', this.onRetry});

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
            text: text,
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(
              color: AppColors.greyColor3,
            ),
          ),
          if (onRetry != null) _RetryButton(onRetry: onRetry!),
        ],
      ),
    );
  }
}

/// آخر اللستة: لودينج الصفحة الجاية أو زرار إعادة المحاولة لو فشلت
class _ListFooter extends StatelessWidget {
  final BaseState<PartnerOrder> state;
  final VoidCallback onRetry;

  const _ListFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }
    if (state.isLoadingMoreFauilare) {
      return Center(child: _RetryButton(onRetry: onRetry));
    }
    return const SizedBox.shrink();
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
      label: LocalizedLabel(
        text: 'try_again',
        style: TextStyles.darkBold14.copyWith(color: AppColors.primaryColor),
      ),
    );
  }
}

/// لودينج أول صفحة
class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      itemCount: 4,
      separatorBuilder: (_, _) => Gap(14.h),
      itemBuilder: (_, _) => const OrderCardSkeleton(),
    );
  }
}
