import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/realtime/driver_offer_alert.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/driver_offer_tile.dart';
import 'package:lavanderia_partner/features/trips/presentation/view_model/driver_offers_cubit.dart';
import 'package:lavanderia_partner/features/trips/presentation/view_model/trips_cubits.dart';
import 'package:lavanderia_partner/main.dart';

/// شيت عروض الدليفرية اللي بيطلع فوق أي شاشة، فيه كل الرحلات اللي عليها
/// عروض ولسه المغسلة مااختارتش، وبيتحدث لحظياً من [DriverOffersCubit]
abstract final class DriverOffersSheet {
  /// الشيت ظاهر دلوقتي، عشان مايتفتحش مرتين والشريط يستخبى
  static final ValueNotifier<bool> isOpen = ValueNotifier(false);

  /// عرض جديد وصل لحظياً أو من إشعار
  /// صفحة طلبه مفتوحة أو الشيت ظاهر: رنّة واحدة والعرض بيظهر قدامه لوحده
  /// غير كده: الشيت بيطلع على الرحلة دي والرنّة بتفضل لحد ما حد يلمسه
  static void announce(int tripId) {
    final orderId = DriverOffersCubit.instance.offersFor(tripId)?.order?.id;
    final isOrderOpen =
        orderId != null && OrderDetailsScreen.openOrderIds.contains(orderId);
    if (isOpen.value || isOrderOpen) {
      DriverOfferAlert.chimeOnce();
      return;
    }
    show(focusTripId: tripId, ring: true);
  }

  /// [focusTripId] بتظهر أول واحدة، و [ring] بيشغّل الرنّة مع الشيت
  static Future<void> show({int? focusTripId, bool ring = false}) async {
    if (isOpen.value || DriverOffersCubit.instance.state.isEmpty) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    isOpen.value = true;
    if (ring) {
      DriverOfferAlert.startRinging();
    } else {
      HapticFeedback.mediumImpact();
    }
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.semiWhiteColor3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        builder: (_) => _DriverOffersSheet(focusTripId: focusTripId),
      );
    } finally {
      isOpen.value = false;
      DriverOfferAlert.stop();
    }
  }
}

class _DriverOffersSheet extends StatelessWidget {
  final int? focusTripId;

  const _DriverOffersSheet({this.focusTripId});

  /// الرحلة اللي الشيت اتفتح عشانها الأول، والباقي بترتيب وصول عروضهم
  List<TripOffers> _ordered(List<TripOffers> offers) => [
    ...offers.where((offer) => offer.tripId == focusTripId),
    ...offers.where((offer) => offer.tripId != focusTripId),
  ];

  /// مفيش عروض باقية، والشيت ممكن مايبقاش اللي فوق لو فيه ديالوج عليه
  void _close(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    route.isCurrent ? navigator.pop() : navigator.removeRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    // أي لمسة في الشيت معناها إن حد شاف العروض، فالرنّة تقف
    return Listener(
      onPointerDown: (_) => DriverOfferAlert.stop(),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            BlocConsumer<DriverOffersCubit, List<TripOffers>>(
              bloc: DriverOffersCubit.instance,
              listenWhen: (previous, current) => current.isEmpty,
              listener: (context, _) => _close(context),
              builder: (context, offers) => ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.semiWhiteColor2,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Gap(14.h),
                  _SheetHeader(count: DriverOffersCubit.countOf(offers)),
                  Gap(16.h),
                  for (final offer in _ordered(offers))
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: _TripOffersSection(
                        key: ValueKey(offer.tripId),
                        offers: offer,
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

/// أيقونة وعنوان الشيت وتحته عدد العروض، وزرار القفل
class _SheetHeader extends StatelessWidget {
  final int count;

  const _SheetHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delivery_dining_rounded,
            color: AppColors.primaryColor,
            size: 24.sp,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedLabel(
                text: 'driver_offers_title',
                style: TextStyles.boldStyle(18, weight: FontWeight.w800),
              ),
              Gap(2.h),
              Label(
                text: 'driver_offers_waiting'.plural(count),
                maxLines: 1,
                style: TextStyles.darkRegular12.copyWith(
                  color: AppColors.greyColor3,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(
            Icons.close_rounded,
            size: 22.sp,
            color: AppColors.greyColor3,
          ),
        ),
      ],
    );
  }
}

/// عروض رحلة واحدة: رقم الطلب ونوع الرحلة فوق، وتحتهم الدليفرية الأقرب الأول
/// القبول والرفض هنا بنفس [TripRequestActionCubit] بتاع كارت تفاصيل الطلب
class _TripOffersSection extends StatefulWidget {
  final TripOffers offers;

  const _TripOffersSection({super.key, required this.offers});

  @override
  State<_TripOffersSection> createState() => _TripOffersSectionState();
}

class _TripOffersSectionState extends State<_TripOffersSection> {
  late final TripRequestActionCubit _actionCubit = TripRequestActionCubit(
    getIt<TripsDataSource>(),
    widget.offers.tripId,
  );

  @override
  void dispose() {
    _actionCubit.close();
    super.dispose();
  }

  /// الرحلة بتختفي من الشيت لوحدها بعد القبول، فالرسالة على الصفحة اللي تحته
  void _onActionStateChanged(
    BuildContext context,
    BaseState<TripRequest> state,
  ) {
    if (state.isSuccess && (state.data?.isApproved ?? false)) {
      navigatorKey.currentContext?.showSuccessMessage('driver_approved'.tr());
      OrdersCubit.notifyServerChanged(widget.offers.order?.id);
      return;
    }
    // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
    final failure = state.failure;
    if (state.isFailure &&
        (failure is ServerFailure || failure is UnknownFailure)) {
      CustomErrorOverlay.show(context: context, text: failure!.message);
    }
  }

  void _openOrder(PartnerOrder order) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = widget.offers;
    final order = offers.order;
    final type = offers.type;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Label(
                  text:
                      order?.displayNumber ?? 'driver_offer_order_loading'.tr(),
                  maxLines: 1,
                  style: TextStyles.boldStyle(15, weight: FontWeight.w800),
                ),
              ),
              if (type != null) ...[Gap(8.w), _TripTypeChip(type: type)],
              const Spacer(),
              if (order != null)
                TextButton(
                  onPressed: () => _openOrder(order),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  child: LocalizedLabel(
                    text: 'view_details',
                    style: TextStyles.boldStyle(
                      13,
                      color: AppColors.primaryColor,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          Gap(10.h),
          BlocConsumer<TripRequestActionCubit, BaseState<TripRequest>>(
            bloc: _actionCubit,
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: _onActionStateChanged,
            builder: (context, actionState) => Column(
              children: [
                for (final (index, request) in offers.requests.indexed)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == offers.requests.length - 1 ? 0 : 10.h,
                    ),
                    child: DriverOfferTile(
                      key: ValueKey(request.id),
                      request: request,
                      isClosest: index == 0 && offers.requests.length > 1,
                      loadingAction:
                          actionState.isLoading &&
                              _actionCubit.pendingRequestId == request.id
                          ? _actionCubit.pendingAction
                          : null,
                      isBusy: actionState.isLoading,
                      onApprove: () => _actionCubit.approve(request),
                      onReject: () => _actionCubit.reject(request),
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

/// استلام من العميل أو توصيل للعميل
class _TripTypeChip extends StatelessWidget {
  final DeliveryTripType type;

  const _TripTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final isPickup = type == DeliveryTripType.pickup;
    final color = isPickup ? const Color(0xffB26A00) : const Color(0xff0E8C4F);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: LocalizedLabel(
        text: isPickup ? 'trip_type_pickup' : 'trip_type_dropoff',
        style: TextStyles.boldStyle(11, color: color, weight: FontWeight.w700),
      ),
    );
  }
}

/// شريط ثابت فوق البار السفلي طول ما فيه عروض مستنية والشيت مقفول
/// الضغط عليه بيفتح الشيت تاني
class DriverOffersStrip extends StatelessWidget {
  const DriverOffersStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DriverOffersSheet.isOpen,
      builder: (context, isSheetOpen, _) =>
          BlocBuilder<DriverOffersCubit, List<TripOffers>>(
            bloc: DriverOffersCubit.instance,
            builder: (context, offers) {
              final count = DriverOffersCubit.countOf(offers);
              final isVisible = count > 0 && !isSheetOpen;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: isVisible
                    ? _StripBody(
                        key: const ValueKey('driver_offers_strip'),
                        count: count,
                        focusTripId: offers.first.tripId,
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
    );
  }
}

class _StripBody extends StatefulWidget {
  final int count;
  final int focusTripId;

  const _StripBody({super.key, required this.count, required this.focusTripId});

  @override
  State<_StripBody> createState() => _StripBodyState();
}

class _StripBodyState extends State<_StripBody>
    with SingleTickerProviderStateMixin {
  /// الجرس بينبض عشان الشريط يلفت النظر
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryColor,
      elevation: 6,
      shadowColor: AppColors.primaryColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => DriverOffersSheet.show(focusTripId: widget.focusTripId),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.2).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.whiteColor,
                  size: 22.sp,
                ),
              ),
              Gap(10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Label(
                      text: 'driver_offers_waiting'.plural(widget.count),
                      maxLines: 1,
                      style: TextStyles.boldStyle(
                        14,
                        color: AppColors.whiteColor,
                        weight: FontWeight.w700,
                      ),
                    ),
                    LocalizedLabel(
                      text: 'driver_offers_tap_to_choose',
                      maxLines: 1,
                      style: TextStyles.darkRegular12.copyWith(
                        color: AppColors.whiteColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                context.isArabic
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: AppColors.whiteColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
