import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/router/bottom_nav_controller.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_adjustment_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_actions_panel.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_timeline.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/order_action_cubit.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/order_details_cubit.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/driver_tile.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/trip_otp_sheet.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/trip_requests_card.dart';

/// بيفتح تفاصيل طلب من الـ id بس، زي لما اليوزر يضغط على إشعار
Future<void> openOrderDetailsById(BuildContext context, int orderId) async {
  final navigator = Navigator.of(context);
  context.showLoadingDialog(message: 'loading');

  final result = await getIt<OrdersDataSource>().getOrder(orderId);
  // بيقفل اللودينج
  navigator.pop();

  result.fold(
    (_) => navigator.context.showErrorMessage('order_not_found'.tr()),
    (order) {
      navigator.push(
        MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
      );
    },
  );
}

/// صفحة تفاصيل الطلب
/// أي تعديل بيتبعت لـ [OrdersCubit.notifyChanged] عشان كل الليستات تحدّث نفسها
class OrderDetailsScreen extends StatefulWidget {
  final PartnerOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderDetailsCubit _detailsCubit = OrderDetailsCubit(
    getIt<OrdersDataSource>(),
    widget.order,
  );

  final OrderActionCubit _actionCubit = OrderActionCubit(
    getIt<OrdersDataSource>(),
  );

  @override
  void dispose() {
    _detailsCubit.close();
    _actionCubit.close();
    super.dispose();
  }

  PartnerOrder get _order => _detailsCubit.order;

  /// الكود اللي الدليفري بيوريه للمغسلة، في الاستلام أو التسليم
  /// [nextStatus] الحالة المتوقعة لحد ما السيرفر يرد بالحقيقية
  Future<void> _confirmTripOtp(
    DeliveryTrip? trip, {
    required String successKey,
    required PartnerOrderStatus nextStatus,
  }) async {
    if (trip == null) return;

    final confirmed = await showTripOtpSheet(context: context, trip: trip);
    if (confirmed != true || !mounted) return;

    context.showSuccessMessage(successKey.tr());
    OrdersCubit.notifyChanged(_order.copyWith(status: nextStatus));
    _detailsCubit.refresh();
  }

  Future<void> _reportMismatch() async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderAdjustmentScreen(order: _order)),
    );
    if (sent == true) _detailsCubit.refresh();
  }

  /// القبول بيروح لطلباتي والرفض الليستات بتشيله لوحدها،
  /// والباقي بيفضل في الصفحة ويجيب الطلب من جديد
  void _onActionStateChanged(
    BuildContext context,
    BaseState<PartnerOrder> state,
  ) {
    if (state.isSuccess) {
      switch (_actionCubit.pendingAction) {
        case OrderAction.accept || OrderAction.reject:
          final accepted = _actionCubit.pendingAction == OrderAction.accept;
          Navigator.of(context).pop();
          if (accepted) BottomNavController.instance.goTo(BottomNavTab.orders);
        case OrderAction.confirmMatch:
          context.showSuccessMessage(
            'match_confirmed'.tr(args: [formatAmount(_order.itemsTotal)]),
          );
          _detailsCubit.refresh();
        case OrderAction.markReady:
          context.showSuccessMessage('order_marked_ready'.tr());
          _detailsCubit.refresh();
        case OrderAction.retryPickup:
          context.showSuccessMessage('pickup_retry_requested'.tr());
          _detailsCubit.refresh();
        case OrderAction.cancelAfterFailedPickup:
          context.showSuccessMessage('order_cancelled'.tr());
          _detailsCubit.refresh();
        case OrderAction.confirmReturn:
          context.showSuccessMessage('return_confirmed'.tr());
          _detailsCubit.refresh();
        case null:
          break;
      }
      return;
    }
    // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
    final failure = state.failure;
    if (state.isFailure &&
        (failure is ServerFailure || failure is UnknownFailure)) {
      context.showErrorMessage(failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderActionCubit, BaseState<PartnerOrder>>(
      bloc: _actionCubit,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onActionStateChanged,
      child: BlocBuilder<OrderDetailsCubit, BaseState<PartnerOrder>>(
        bloc: _detailsCubit,
        builder: (context, detailsState) {
          final order = detailsState.data!;
          final tripCard = _tripCard(order, detailsState.lastUpdated);

          return Scaffold(
            backgroundColor: AppColors.semiWhiteColor3,
            body: Column(
              children: [
                _DetailsHeader(order: order),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: _detailsCubit.refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                      child: Column(
                        children: [
                          OrderStatusHint(order: order),
                          Gap(14.h),
                          CustomerInfoCard(order: order),
                          Gap(14.h),
                          if (tripCard != null) ...[tripCard, Gap(14.h)],
                          OrderItemsCard(order: order),
                          Gap(14.h),
                          OrderMetaCard(order: order),
                          Gap(14.h),
                          DetailsCard(
                            titleKey: 'order_stages',
                            child: OrderTimeline(currentStage: order.stage),
                          ),
                          Gap(20.h),
                          BlocBuilder<
                            OrderActionCubit,
                            BaseState<PartnerOrder>
                          >(
                            bloc: _actionCubit,
                            builder: (context, state) => OrderActionsPanel(
                              order: order,
                              loadingAction: state.isLoading
                                  ? _actionCubit.pendingAction
                                  : null,
                              onAccept: () => _actionCubit.accept(order),
                              onReject: () => _actionCubit.reject(order),
                              onConfirmPickup: () => _confirmTripOtp(
                                order.pickupTrip,
                                successKey: 'pickup_confirmed',
                                nextStatus:
                                    PartnerOrderStatus.atLaundryPendingMatch,
                              ),
                              onConfirmHandover: () => _confirmTripOtp(
                                order.dropoffTrip,
                                successKey: 'handover_confirmed',
                                nextStatus: PartnerOrderStatus.outForDelivery,
                              ),
                              onRetryPickup: () =>
                                  _actionCubit.retryPickup(order),
                              onCancelAfterFailedPickup: () =>
                                  _actionCubit.cancelAfterFailedPickup(order),
                              onConfirmReturn: () =>
                                  _actionCubit.confirmReturn(order),
                              onConfirmMatch: () =>
                                  _actionCubit.confirmMatch(order),
                              onReportMismatch: _reportMismatch,
                              onMarkReady: () => _actionCubit.markReady(order),
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
        },
      ),
    );
  }

  /// كارت رحلة الاستلام أو التسليم حسب الحالة:
  /// الدليفري المتعيّن لو فيه، وإلا الدليفرية اللي طلبوا الرحلة
  /// وقت المطابقة كارت الاستلام بيفضل ظاهر عشان صور الهدوم اللي الدليفري رفعها
  /// [refreshedAt] جوه الـ key عشان الكارت يجيب الطلبات تاني مع كل تحديث
  Widget? _tripCard(PartnerOrder order, DateTime? refreshedAt) {
    final trip = switch (order.status) {
      PartnerOrderStatus.awaitingPickup ||
      PartnerOrderStatus.pickupFailed ||
      PartnerOrderStatus.atLaundryPendingMatch ||
      PartnerOrderStatus.adjustmentPendingApproval => order.pickupTrip,
      PartnerOrderStatus.ready ||
      PartnerOrderStatus.awaitingDropoffCollection ||
      PartnerOrderStatus.outForDelivery ||
      PartnerOrderStatus.deliveryFailed => order.dropoffTrip,
      _ => null,
    };
    if (trip == null) return null;
    if (trip.hasDriver) return AssignedDriverCard(trip: trip);
    // طلبات الدليفرية بتتقبل بس والرحلة لسه مستنية دليفري
    final isWaitingDriver =
        order.status == PartnerOrderStatus.awaitingPickup ||
        order.status == PartnerOrderStatus.ready;
    if (!isWaitingDriver) return null;
    return TripRequestsCard(
      key: ValueKey('${trip.id}-$refreshedAt'),
      trip: trip,
      onApproved: _detailsCubit.refresh,
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
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Label(
                  text: order.displayNumber,
                  maxLines: 1,
                  style: TextStyles.whiteText(19, weight: FontWeight.w800),
                ),
                // Gap(8.h),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
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
          ),
        ],
      ),
    );
  }
}
