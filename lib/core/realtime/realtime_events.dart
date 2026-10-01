import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';

/// الأحداث اللحظية اللي مالهاش مكان في [OrdersCubit]
/// زي طلبات الدليفرية على الرحلة، كارت الطلبات المفتوح بيسمع عليها
abstract final class RealtimeEvents {
  /// TripRequested و TripRequestCancelled، الحالة جوه الطلب بتفرّق بينهم
  static final StreamController<TripRequest> _tripRequests =
      StreamController<TripRequest>.broadcast();

  static Stream<TripRequest> get tripRequests => _tripRequests.stream;

  static void notifyTripRequest(TripRequest request) =>
      _tripRequests.add(request);

  /// فيه إشعار جديد اتحفظ ولسه صفحة الإشعارات ماتفتحتش
  /// كل حدث بيتحفظ كإشعار ما عدا TripRequestCancelled
  static final ValueNotifier<bool> hasUnreadNotifications = ValueNotifier(
    false,
  );
}
