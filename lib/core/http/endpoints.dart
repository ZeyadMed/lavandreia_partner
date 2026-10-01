abstract interface class Endpoints {
  static const String baseUrl = 'https://lavanderia.runasp.net/';
  static const String updateLocation = '';

  /// الـ SignalR hub، التوكن بيتبعت فيه كـ ?access_token
  static const String ordersHub = 'hubs/orders';

  // ****************************** Auth ********************************
  static const String register = 'api/auth/laundry/register';

  /// المدن اللي بتتعرض في دروب داون التسجيل، بتقبل ?search اختياري
  static const String cities = 'api/auth/cities';

  /// تأكيد رقم المغسلة بعد التسجيل، بتستقبل { phoneNumber, code }
  static const String verifyPhone = 'api/auth/laundry/verify-phone';

  /// بتستقبل { phoneNumber, password, rememberMe, deviceToken }
  static const String login = 'api/auth/laundry/login';
  static const String forgetPassword = 'forgot/password';
  static const String resetPasssword = 'forgot/reset-password';
  static const String confirmPassword = '';
  static const String resentOtp = 'resend-otp';
  static const String forgetResendOtp = 'forgot/resend-otp';
  static const String forgetVerifyOtp = 'forgot/verify-otp';
  static const String logOut = '/api/auth/logout';

  /// بناخد منها accessToken جديد لما القديم يقع بـ 401.
  /// بتستقبل { "refreshToken": "..." } وبترجع الاتنين جداد.
  static const String refreshToken = '/api/auth/refresh-token';

  // ****************************** Laundry ********************************
  /// بيانات المغسلة: الاسم والصورة والعنوان وغيرهم
  static const String laundryProfile = 'api/laundry/profile';

  /// كل الخدمات اللي المغسلة تقدر تقدمها
  static const String laundryServices = 'api/laundry/services';

  /// أصناف خدمة معينة، بدّل {serviceId} بـ [serviceItems]
  static const String servicesItems = 'api/laundry/services/{serviceId}/items';

  /// أصناف المغسلة بأسعارها:
  /// GET بيجيبها، POST و PUT بيستقبلوا { items: [{ serviceItemId, price }] }
  /// و DELETE بيستقبل { serviceItemIds: [..] }
  static const String myServices = 'api/laundry/my-services';

  /// مواعيد عمل المغسلة: GET بيجيبها،
  /// و PUT بيستقبل { workingHours: [{ dayOfWeek, openTime, closeTime, isClosed }] }
  static const String workingHours = 'api/laundry/working-hours';

  /// تقييمات العملاء للمغسلة، بتقبل ?PageIndex و ?PageSize
  static const String laundryReviews = 'api/laundry/reviews';

  static String serviceItems(int serviceId) =>
      servicesItems.replaceFirst('{serviceId}', '$serviceId');

  /// طلبات المغسلة، بتقبل ?PageIndex و ?PageSize
  static const String orders = 'api/laundry/orders';

  /// طلب واحد بكل تفاصيله ورحلاته، GET
  static String order(int orderId) => '$orders/$orderId';

  /// قبول الطلب الجديد، POST من غير body
  static String acceptOrder(int orderId) => '$orders/$orderId/accept';

  /// رفض الطلب الجديد، POST من غير body
  static String rejectOrder(int orderId) => '$orders/$orderId/reject';

  /// الهدوم اللي وصلت مطابقة للطلب، POST من غير body
  static String confirmOrderMatch(int orderId) =>
      '$orders/$orderId/confirm-match';

  /// تعديل أصناف الطلب لما اللي وصل يختلف عن اللي اتطلب، POST بـ
  /// { items: [{ orderItemId, action: Replace | Add | Remove,
  /// newServiceItemId, newQuantity }] }
  static String orderAdjustments(int orderId) => '$orders/$orderId/adjustments';

  /// الغسيل خلص والطلب جاهز للتسليم، POST من غير body
  static String markOrderReady(int orderId) => '$orders/$orderId/ready';

  /// الدليفرية اللي طلبوا رحلة، GET
  static String tripRequests(int tripId) =>
      'api/laundry/trips/$tripId/requests';

  /// الموافقة على دليفري للرحلة وباقي الطلبات بتترفض لوحدها، POST من غير body
  static String approveTripRequest(int tripId, int requestId) =>
      '${tripRequests(tripId)}/$requestId/approve';

  /// رفض طلب دليفري واحد، POST من غير body
  static String rejectTripRequest(int tripId, int requestId) =>
      '${tripRequests(tripId)}/$requestId/reject';

  /// تأكيد تسليم الهدوم لدليفري التسليم، POST بـ { otpCode }
  static String confirmDropoffHandover(int tripId) =>
      'api/laundry/dropoff-trips/$tripId/confirm-handover';

  /// بعد فشل الاستلام: POST بـ { retry: true } لرحلة جديدة
  /// أو { retry: false } لإلغاء الطلب
  static String resolveFailedPickup(int orderId) =>
      '$orders/$orderId/failed-pickup/resolve';

  /// بعد فشل التوصيل: المغسلة استلمت الهدوم راجعة، POST من غير body
  static String confirmFailedDropoffReturn(int orderId) =>
      '$orders/$orderId/failed-dropoff/confirm-return';

  /// تأكيد استلام الهدوم من دليفري الاستلام، POST بـ { otpCode }
  static String confirmPickupTrip(int tripId) =>
      'api/laundry/pickup-trips/$tripId/confirm';

  /// رصيد محفظة المغسلة
  static const String wallet = 'api/laundry/wallet';

  /// حركات المحفظة، بتقبل ?PageIndex و ?PageSize
  static const String walletTransactions = '$wallet/transactions';

  /// إشعارات المغسلة: GET بيجيبها وبيقبل ?PageIndex و ?PageSize،
  /// و DELETE بيمسحها كلها
  static const String notifications = 'api/laundry/notifications';

  /// تعليم كل الإشعارات كمقروءة، PUT من غير body
  static const String readAllNotifications = '$notifications/read-all';

  /// DELETE بيمسح إشعار واحد
  static String notification(int notificationId) =>
      '$notifications/$notificationId';

  /// تعليم إشعار واحد كمقروء، PUT من غير body
  static String readNotification(int notificationId) =>
      '$notifications/$notificationId/read';
}
