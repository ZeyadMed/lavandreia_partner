import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// نتيجة محاولة جلب الموقع، عشان الـ UI يعرف يفرق بين الحالات
/// ويقرر يعرض العنوان ولا رسالة "حدد موقعك"
enum LocationStatus {
  /// اتجاب العنوان تمام
  success,

  /// اليوزر رفض المرة دي بس ممكن نسأله تاني
  denied,

  /// رفض نهائي، مش هينفع نسأل تاني غير من إعدادات التطبيق
  deniedForever,

  /// الـ GPS نفسه مقفول من إعدادات الجهاز
  serviceDisabled,

  /// حصل error وقت الجلب أو تحويل الإحداثيات لعنوان
  failed,
}

/// الموقع بعد ما يتجاب: الحالة ومعاها العنوان والإحداثيات
class LocationResult {
  final LocationStatus status;

  /// العنوان المختصر اللي بيتعرض في الهيدر، فاضي لو الحالة مش success
  final String address;
  final double? latitude;
  final double? longitude;

  const LocationResult({
    required this.status,
    this.address = '',
    this.latitude,
    this.longitude,
  });

  bool get isSuccess => status == LocationStatus.success;

  /// بيتعرض عليه زرار الإعدادات لأن السؤال العادي مش هيظهر تاني
  bool get needsSettings => status == LocationStatus.deniedForever;
}

/// بيجيب موقع اليوزر الحالي ويحوله لعنوان مقروء
/// مفصول عن الـ UI عشان أي شاشة تقدر تستخدمه، ومش بيرمي exceptions
/// بيرجع الحالة في LocationResult والـ UI هو اللي بيقرر يعرض إيه
class LocationService {
  final Geocoding _geocoding = Geocoding();

  /// بيتأكد إن الـ GPS شغال والصلاحية متاخدة، وبيطلبها لو لسه
  /// أي حاجة فيهم ممكن تعلق لو الplugin مش متسطب صح، فكلها بتايم أوت
  Future<LocationStatus> _ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 5));
      if (!serviceEnabled) return LocationStatus.serviceDisabled;

      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 5),
      );

      if (permission == LocationPermission.denied) {
        // هنا بالظبط بيظهر للـ يوزر سؤال الصلاحية بتاع النظام
        // من غير تايم أوت لأن اليوزر ممكن ياخد وقته في الرد
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return LocationStatus.denied;
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationStatus.deniedForever;
      }
      return LocationStatus.success;
    } catch (_) {
      return LocationStatus.failed;
    }
  }

  /// بيجيب الإحداثيات ويحولها لعنوان مختصر
  /// أي error بيترجع كـ failed عشان الهيدر مايقعش
  Future<LocationResult> getCurrentAddress() async {
    final permissionStatus = await _ensurePermission();
    if (permissionStatus != LocationStatus.success) {
      return LocationResult(status: permissionStatus);
    }

    try {
      final position = await _readPosition();
      if (position == null) {
        return const LocationResult(status: LocationStatus.failed);
      }

      final address = await _addressOf(position);

      return LocationResult(
        status: LocationStatus.success,
        address: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(status: LocationStatus.failed);
    }
  }

  /// بيجيب الإحداثيات مع تايم أوت مضمون
  /// الـ timeLimit بتاع الplugin لوحده مش كفاية لأنه أحياناً مابيرجعش خالص
  /// (مثلاً لو البودز مش متسطبة أو الـ GPS بيلف من غير ما يلاقي)
  /// فبنلف عليه .timeout كمان عشان اللودينج مايعلقش للأبد
  Future<Position?> _readPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      // لو فشل نجرب آخر موقع معروف، غالباً بيرجع على طول
      // وأحسن من إننا نسيب اليوزر من غير عنوان
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// بيحول الإحداثيات لعنوان، ولو الـ geocoding فشل بيرجع الإحداثيات نفسها
  /// عشان اليوزر يشوف حاجة بدل ما الهيدر يفضل فاضي
  Future<String> _addressOf(Position position) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 10));
      if (placemarks.isEmpty) return _coordinatesOf(position);

      final address = _formatPlacemark(placemarks.first);
      return address.isEmpty ? _coordinatesOf(position) : address;
    } catch (_) {
      return _coordinatesOf(position);
    }
  }

  /// "حي الأندلس، طرابلس" - بنجمع أدق حاجتين موجودين بس
  /// عشان العنوان الطويل مايكسرش سطر الهيدر
  String _formatPlacemark(Placemark place) {
    final parts = [
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.country,
    ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();

    return parts.take(2).join('، ');
  }

  String _coordinatesOf(Position position) =>
      '${position.latitude.toStringAsFixed(3)}, '
      '${position.longitude.toStringAsFixed(3)}';

  /// بيفتح إعدادات التطبيق عشان اليوزر يفعّل الصلاحية بنفسه
  /// بيتنادى لما تكون الحالة deniedForever
  Future<void> openSettings() => Geolocator.openAppSettings();

  /// بيفتح إعدادات الموقع في النظام لما الـ GPS يكون مقفول
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
