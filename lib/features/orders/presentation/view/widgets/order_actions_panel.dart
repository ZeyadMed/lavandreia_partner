import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/order_action_cubit.dart';

/// زراير الطلب تحت صفحة التفاصيل، كل حالة بتظهر الأكشن المسموح بيه بس
/// الحالات اللي المغسلة مستنية فيها حد تاني مبيظهرش فيها زراير
class OrderActionsPanel extends StatelessWidget {
  final PartnerOrder order;

  /// الزرار اللي بيحمّل دلوقتي، والباقي بيتقفل لحد ما يخلص
  final OrderAction? loadingAction;

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onConfirmPickup;
  final VoidCallback onConfirmMatch;
  final VoidCallback onReportMismatch;
  final VoidCallback onMarkReady;
  final VoidCallback onConfirmHandover;
  final VoidCallback onRetryPickup;
  final VoidCallback onCancelAfterFailedPickup;
  final VoidCallback onConfirmReturn;

  const OrderActionsPanel({
    super.key,
    required this.order,
    required this.loadingAction,
    required this.onAccept,
    required this.onReject,
    required this.onConfirmPickup,
    required this.onConfirmMatch,
    required this.onReportMismatch,
    required this.onMarkReady,
    required this.onConfirmHandover,
    required this.onRetryPickup,
    required this.onCancelAfterFailedPickup,
    required this.onConfirmReturn,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = loadingAction != null;

    return switch (order.status) {
      PartnerOrderStatus.newOrder => Row(
        children: [
          Expanded(
            child: OrderActionButton(
              labelKey: 'accept_order',
              isLoading: loadingAction == OrderAction.accept,
              onTap: isBusy ? null : onAccept,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: OrderActionButton(
              labelKey: 'reject_order',
              isPrimary: false,
              foreground: AppColors.redColor2,
              isLoading: loadingAction == OrderAction.reject,
              onTap: isBusy ? null : onReject,
            ),
          ),
        ],
      ),
      // الكود بيتأكد لما الدليفري المتعيّن يوصل المغسلة بالهدوم
      // الزرار ظاهر طول ما فيه رحلة، لأن بيانات الدليفري مش مضمون ترجع في
      // ريسبونس الطلب، والسيرفر هو اللي بيرفض لو مفيش دليفري لسه
      PartnerOrderStatus.awaitingPickup when order.pickupTrip != null =>
        OrderActionButton(
          labelKey: 'confirm_pickup_received',
          onTap: onConfirmPickup,
        ),
      PartnerOrderStatus.atLaundryPendingMatch => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderActionButton(
            labelKey: 'confirm_match',
            isLoading: loadingAction == OrderAction.confirmMatch,
            onTap: isBusy ? null : onConfirmMatch,
          ),
          Gap(10.h),
          OrderActionButton(
            labelKey: 'report_mismatch',
            isPrimary: false,
            foreground: const Color(0xffC2410C),
            onTap: isBusy ? null : onReportMismatch,
          ),
        ],
      ),
      PartnerOrderStatus.inProgress => OrderActionButton(
        labelKey: 'mark_order_ready',
        isLoading: loadingAction == OrderAction.markReady,
        onTap: isBusy ? null : onMarkReady,
      ),
      // الكود بيتأكد لما دليفري التسليم ييجي ياخد الهدوم
      PartnerOrderStatus.awaitingDropoffCollection
          when order.dropoffTrip != null =>
        OrderActionButton(
          labelKey: 'confirm_handover',
          onTap: onConfirmHandover,
        ),
      PartnerOrderStatus.pickupFailed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderActionButton(
            labelKey: 'retry_pickup',
            isLoading: loadingAction == OrderAction.retryPickup,
            onTap: isBusy ? null : onRetryPickup,
          ),
          Gap(10.h),
          OrderActionButton(
            labelKey: 'cancel_order',
            isPrimary: false,
            foreground: AppColors.redColor2,
            isLoading: loadingAction == OrderAction.cancelAfterFailedPickup,
            onTap: isBusy ? null : onCancelAfterFailedPickup,
          ),
        ],
      ),
      PartnerOrderStatus.deliveryFailed => OrderActionButton(
        labelKey: 'confirm_return_received',
        isLoading: loadingAction == OrderAction.confirmReturn,
        onTap: isBusy ? null : onConfirmReturn,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// بانر صغير فوق صفحة التفاصيل بيقول المغسلة مستنية إيه أو المفروض تعمل إيه
class OrderStatusHint extends StatelessWidget {
  final PartnerOrder order;

  const OrderStatusHint({super.key, required this.order});

  String? get _hintKey => switch (order.status) {
    PartnerOrderStatus.awaitingPickup =>
      order.pickupTrip?.hasDriver ?? false
          ? 'hint_pickup_driver_assigned'
          : 'hint_waiting_pickup_driver',
    PartnerOrderStatus.atLaundryPendingMatch => 'hint_count_clothes',
    PartnerOrderStatus.adjustmentPendingApproval =>
      'hint_waiting_adjustment_response',
    PartnerOrderStatus.inProgress => 'hint_mark_ready',
    PartnerOrderStatus.ready => 'hint_waiting_dropoff_driver',
    PartnerOrderStatus.outForDelivery => 'hint_out_for_delivery',
    PartnerOrderStatus.awaitingDropoffCollection =>
      'hint_awaiting_dropoff_collection',
    PartnerOrderStatus.pickupFailed => 'hint_pickup_failed',
    PartnerOrderStatus.deliveryFailed => 'hint_delivery_failed',
    _ => null,
  };

  /// سبب الفشل اللي الدليفري كتبه، بيظهر تحت البانر
  String get _failureText {
    final trip = switch (order.status) {
      PartnerOrderStatus.pickupFailed => order.pickupTrip,
      PartnerOrderStatus.deliveryFailed => order.dropoffTrip,
      _ => null,
    };
    if (trip == null) return '';
    final reason = trip.failureReason.isEmpty
        ? ''
        : 'failure_reason_${trip.failureReason}'.tr();
    return [reason, trip.failureNote].where((t) => t.isNotEmpty).join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final hintKey = _hintKey;
    if (hintKey == null) return const SizedBox.shrink();

    final color = order.status.foregroundColor;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: order.status.backgroundColor,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18.sp, color: color),
          Gap(10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedLabel(
                  text: hintKey,
                  style: TextStyles.boldStyle(
                    13,
                    color: color,
                    weight: FontWeight.w600,
                  ),
                ),
                if (_failureText.isNotEmpty) ...[
                  Gap(4.h),
                  Label(
                    text: _failureText,
                    style: TextStyles.darkRegular12.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// زرار الأكشن الكبير، الأساسي أزرق والتاني خلفيته فاتحة من نفس لون النص
/// وهو بيحمّل بيظهر لودينج مكان النص
class OrderActionButton extends StatelessWidget {
  final String labelKey;
  final bool isPrimary;
  final Color foreground;
  final bool isLoading;
  final VoidCallback? onTap;

  const OrderActionButton({
    super.key,
    required this.labelKey,
    this.isPrimary = true,
    this.foreground = AppColors.whiteColor,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isPrimary
        ? AppColors.primaryColor
        : foreground.withValues(alpha: 0.1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: foreground,
                ),
              )
            : LocalizedLabel(
                text: labelKey,
                style: TextStyles.boldStyle(
                  16,
                  color: foreground,
                  weight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
