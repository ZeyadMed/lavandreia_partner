import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/token_refresh_service.dart';
import 'package:lavanderia_partner/core/realtime/realtime_events.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/features/orders/data/models/order_adjustment_result.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/new_order_dialog.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/main.dart';
import 'package:signalr_netcore/signalr_client.dart';

enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

/// الاتصال اللحظي بالسيرفر (SignalR) على hubs/orders
/// السيرفر بس اللي بيبعت، والمغسلة بتسمع على أحداث طلباتها ورحلاتها
/// مش في getIt عشان resetGetItAndInit مايقفلوش من غير ما نعرف
abstract final class RealtimeService {
  static HubConnection? _hub;

  static final ValueNotifier<RealtimeStatus> status = ValueNotifier(
    RealtimeStatus.disconnected,
  );

  /// المستخدم لسه logged in، فلو الاتصال وقع نرجّعه
  static bool _shouldBeConnected = false;
  static bool _isForeground = true;

  static Timer? _retryTimer;
  static int _retryAttempt = 0;
  static StreamSubscription<List<ConnectivityResult>>? _connectivity;
  static final _LifecycleObserver _lifecycle = _LifecycleObserver();

  /// طلبات جديدة مستنية البوب أب بتاعها يظهر، واحد ورا التاني
  static final List<PartnerOrder> _pendingNewOrders = [];
  static bool _isShowingNewOrder = false;

  /// آخر تنبيه أكشن ظهر لكل طلب، عشان نفس الحالة ماتنبهش مرتين
  static final Map<int, String> _lastActionPrompt = {};

  /// متصل دلوقتي، فالأحداث بتوصل لحظياً ومحتاجناش إشعار FCM في الـ foreground
  static bool get isLive => status.value == RealtimeStatus.connected;

  /// بيتنادى أول ما الأبلكيشن يدخل بعد اللوجين، وتكراره مش بيعمل حاجة
  static Future<void> connect() async {
    if (!_shouldBeConnected) {
      _shouldBeConnected = true;
      WidgetsBinding.instance.addObserver(_lifecycle);
      _connectivity = Connectivity().onConnectivityChanged.listen(
        _onConnectivityChanged,
      );
    }
    await _start();
  }

  /// في تسجيل الخروج أو لما الجلسة تنتهي
  static Future<void> disconnect() async {
    _shouldBeConnected = false;
    _retryTimer?.cancel();
    _retryAttempt = 0;
    WidgetsBinding.instance.removeObserver(_lifecycle);
    await _connectivity?.cancel();
    _connectivity = null;
    _pendingNewOrders.clear();
    _lastActionPrompt.clear();

    final hub = _hub;
    _hub = null;
    status.value = RealtimeStatus.disconnected;
    try {
      await hub?.stop();
    } catch (e) {
      loggerWarn('Realtime stop failed: $e');
    }
  }

  /// الأحداث اللي فاتت وإحنا مش متصلين مش بتتبعت تاني
  /// فبنجيب الليستات والطلب المفتوح من السيرفر
  static void resync() => OrdersCubit.notifyServerChanged(null);

  static HubConnection _build() {
    final hub = HubConnectionBuilder()
        .withUrl(
          '${Endpoints.baseUrl}${Endpoints.ordersHub}',
          options: HttpConnectionOptions(
            // دايماً أحدث توكن، عشان إعادة الاتصال تاخد اللي اتجدد
            accessTokenFactory: () async =>
                await CacheManager.getAccessToken() ?? '',
            requestTimeout: 15000,
          ),
        )
        .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
        .build();

    hub.onreconnecting(({error}) {
      loggerWarn('Realtime reconnecting: $error');
      status.value = RealtimeStatus.reconnecting;
    });
    hub.onreconnected(({connectionId}) {
      logger('Realtime reconnected');
      status.value = RealtimeStatus.connected;
      resync();
    });
    // إعادة الاتصال التلقائي بتبطّل بعد آخر محاولة، فبنكمل إحنا
    hub.onclose(({error}) {
      loggerWarn('Realtime closed: $error');
      status.value = RealtimeStatus.disconnected;
      _scheduleRetry();
    });

    _on(hub, 'OrderCreated', _onOrderCreated);
    _on(hub, 'OrderUpdated', _onOrderUpdated);
    _on(hub, 'AdjustmentResolved', _onAdjustmentResolved);
    _on(hub, 'TripRequested', _onTripRequested);
    _on(hub, 'TripRequestCancelled', _onTripRequestCancelled);
    _on(hub, 'TripWithdrawn', _onTripWithdrawn);
    return hub;
  }

  /// كل حدث ليه argument واحد بس، وهو الـ payload
  static void _on(
    HubConnection hub,
    String event,
    void Function(Map<String, dynamic> json) handler,
  ) {
    hub.on(event, (arguments) {
      final payload = arguments?.isNotEmpty ?? false ? arguments!.first : null;
      logger('Realtime $event: $payload');
      if (payload is! Map) return;
      try {
        handler(Map<String, dynamic>.from(payload));
      } catch (e, stackTrace) {
        loggerError(stackTrace);
        loggerWarn('Realtime $event handling failed: $e');
      }
    });
  }

  static Future<void> _start({bool isRetry = false}) async {
    if (!_shouldBeConnected) return;
    final hub = _hub ??= _build();
    if (hub.state != HubConnectionState.Disconnected) return;

    _retryTimer?.cancel();
    status.value = isRetry
        ? RealtimeStatus.reconnecting
        : RealtimeStatus.connecting;
    try {
      await hub.start();
      _retryAttempt = 0;
      status.value = RealtimeStatus.connected;
      logger('Realtime connected');
      if (isRetry) resync();
    } catch (e) {
      loggerWarn('Realtime start failed: $e');
      if (!_shouldBeConnected) return;
      status.value = RealtimeStatus.disconnected;
      // التوكن بيتشيك في الـ handshake بس، فلو انتهى بنجدده ونجرب تاني
      if ('$e'.contains('401') && await _refreshToken()) {
        return _start(isRetry: isRetry);
      }
      _scheduleRetry();
    }
  }

  /// true لو اتجدد، ولو الجلسة انتهت بنقفل والـ ApiConsumer هيرجّع للوجين
  static Future<bool> _refreshToken() async {
    if (!getIt.isRegistered<TokenRefreshService>()) return false;
    final result = await getIt<TokenRefreshService>().refresh();
    if (result is RefreshInvalid) await disconnect();
    return result is RefreshSuccess;
  }

  /// 5 ثواني وبعدين 15 وبعدين 30 لحد دقيقة، وبس والأبلكيشن قدام المستخدم
  static void _scheduleRetry() {
    _retryTimer?.cancel();
    if (!_shouldBeConnected || !_isForeground) return;
    const delays = [5, 15, 30, 60];
    final seconds = delays[_retryAttempt.clamp(0, delays.length - 1)];
    _retryAttempt++;
    _retryTimer = Timer(
      Duration(seconds: seconds),
      () => _start(isRetry: true),
    );
  }

  static void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (isOnline && status.value == RealtimeStatus.disconnected) {
      _retryAttempt = 0;
      _start(isRetry: true);
    }
  }

  static void _onResumed() {
    _isForeground = true;
    if (!_shouldBeConnected) return;
    _retryAttempt = 0;
    if (status.value == RealtimeStatus.disconnected) {
      _start(isRetry: true);
    } else {
      resync();
    }
  }

  static void _onPaused() {
    _isForeground = false;
    _retryTimer?.cancel();
  }

  // ****************************** Events ********************************

  static void _onOrderCreated(Map<String, dynamic> json) {
    final order = PartnerOrder.fromJson(json);
    OrdersCubit.notifyCreated(order);
    RealtimeEvents.hasUnreadNotifications.value = true;
    _pendingNewOrders.add(order);
    _showNextNewOrder();
  }

  static Future<void> _showNextNewOrder() async {
    if (_isShowingNewOrder || _pendingNewOrders.isEmpty) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isShowingNewOrder = true;
    HapticFeedback.heavyImpact();
    await showNewOrderDialog(context, _pendingNewOrders.removeAt(0));
    _isShowingNewOrder = false;
    _showNextNewOrder();
  }

  static void _onOrderUpdated(Map<String, dynamic> json) {
    final order = PartnerOrder.fromJson(json);
    OrdersCubit.notifyChanged(order);
    RealtimeEvents.hasUnreadNotifications.value = true;
    _promptActionIfNeeded(order);
  }

  /// الحالات اللي الدليفري بيغيّرها والمغسلة لازم تعمل حاجة بعدها
  static void _promptActionIfNeeded(PartnerOrder order) {
    final messageKey = switch (order.status) {
      PartnerOrderStatus.awaitingPickup
          when order.pickupTrip?.needsLaundryConfirmation ?? false =>
        'realtime_pickup_driver_arrived',
      PartnerOrderStatus.awaitingDropoffCollection
          when order.dropoffTrip?.needsLaundryConfirmation ?? false =>
        'realtime_dropoff_driver_arrived',
      PartnerOrderStatus.pickupFailed => 'realtime_pickup_failed',
      PartnerOrderStatus.deliveryFailed => 'realtime_delivery_failed',
      _ => null,
    };
    if (messageKey == null) {
      _lastActionPrompt.remove(order.id);
      return;
    }
    if (_lastActionPrompt[order.id] == messageKey) return;
    _lastActionPrompt[order.id] = messageKey;
    final isPageOpen = OrderDetailsScreen.openOrderIds.contains(order.id);
    final isDriverArrived =
        messageKey == 'realtime_pickup_driver_arrived' ||
        messageKey == 'realtime_dropoff_driver_arrived';
    if (isDriverArrived) {
      // بنجيب الطلب من السيرفر عشان الصور والرحلة كاملة قبل ما يدخل الكود
      OrdersCubit.notifyServerChanged(order.id);
    } else if (isPageOpen) {
      // الصفحة مفتوحة والزرار ظاهر قدامه
      return;
    }
    // المندوب واقف قدام المغسلة، فالتنبيه بيظهر حتى لو الصفحة مفتوحة
    _showBanner(
      messageKey.tr(args: [order.displayNumber]),
      icon: Icons.notifications_active_outlined,
      orderId: isPageOpen ? null : order.id,
    );
  }

  /// الحالة الجديدة بتيجي لوحدها مع OrderUpdated، هنا بنعرض الرد بس
  static void _onAdjustmentResolved(Map<String, dynamic> json) {
    final adjustment = OrderAdjustmentResult.fromJson(json);
    RealtimeEvents.hasUnreadNotifications.value = true;
    final approved = adjustment.status == OrderAdjustmentStatus.approved;
    _showBanner(
      (approved
              ? 'realtime_adjustment_approved'
              : 'realtime_adjustment_rejected')
          .tr(),
      icon: approved ? Icons.check_circle_outline : Icons.cancel_outlined,
    );
  }

  static void _onTripRequested(Map<String, dynamic> json) {
    final request = TripRequest.fromJson(json);
    RealtimeEvents.notifyTripRequest(request);
    OrdersCubit.notifyTripRequestCountChanged(request.deliveryTripId, 1);
    RealtimeEvents.hasUnreadNotifications.value = true;
    _showBanner(
      'realtime_trip_requested'.tr(args: [request.driverName]),
      icon: Icons.delivery_dining_outlined,
    );
  }

  /// لحظي بس: مش بيتحفظ كإشعار ومفيش push
  static void _onTripRequestCancelled(Map<String, dynamic> json) {
    final request = TripRequest.fromJson(json).copyWith(status: 'Cancelled');
    RealtimeEvents.notifyTripRequest(request);
    OrdersCubit.notifyTripRequestCountChanged(request.deliveryTripId, -1);
  }

  /// الرحلة رجعت مفتوحة، وفي التسليم الطلب بيرجع Ready مع OrderUpdated
  static void _onTripWithdrawn(Map<String, dynamic> json) {
    final trip = DeliveryTrip.fromJson(
      json,
      type: DeliveryTripType.fromApi(json['type']) ?? DeliveryTripType.pickup,
    );
    RealtimeEvents.hasUnreadNotifications.value = true;
    if (trip.orderId != 0) OrdersCubit.notifyServerChanged(trip.orderId);
    _showBanner(
      'realtime_trip_withdrawn'.tr(),
      icon: Icons.person_off_outlined,
      orderId: trip.orderId == 0 ? null : trip.orderId,
    );
  }

  // ****************************** UI ********************************

  /// بانر صغير فوق الشاشة، ولو فيه [orderId] الضغط عليه بيفتح الطلب
  static void _showBanner(String text, {required IconData icon, int? orderId}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late final OverlayEntry entry;
    var isRemoved = false;
    void remove() {
      if (isRemoved) return;
      isRemoved = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        top: MediaQuery.of(context).padding.top + 10,
        child: Material(
          color: AppColors.primaryColor,
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              remove();
              final navigatorContext = navigatorKey.currentContext;
              if (orderId != null && navigatorContext != null) {
                openOrderDetailsById(navigatorContext, orderId);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (orderId != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), remove);
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        RealtimeService._onResumed();
      case AppLifecycleState.paused:
        RealtimeService._onPaused();
      default:
        break;
    }
  }
}
