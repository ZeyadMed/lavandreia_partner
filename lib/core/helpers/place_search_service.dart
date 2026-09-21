import 'dart:convert';

import 'package:http/http.dart' as http;

/// نتيجة بحث واحدة على الخريطة
class PlaceResult {
  /// الاسم الكامل زي ما رجع من الخدمة
  final String displayName;
  final double latitude;
  final double longitude;

  const PlaceResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

/// البحث عن الأماكن والعكس (إحداثيات ← اسم) باستخدام Nominatim
/// مجاني ومش محتاج مفتاح، بس شروط الاستخدام بتطلب User-Agent معرّف
/// ومعدل طلبات معقول، عشان كده البحث مربوط بـ debounce من الشاشة
class PlaceSearchService {
  static const String _base = 'nominatim.openstreetmap.org';

  /// Nominatim بترفض الطلبات اللي من غير User-Agent واضح
  static const Map<String, String> _headers = {
    'User-Agent': 'LavanderiaPartner/1.0 (laundry partner app)',
    'Accept': 'application/json',
  };

  final http.Client _client;

  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();

  /// بيدور على مكان بالاسم
  /// بيرجع ليست فاضية لو مفيش نتايج أو لو حصل أي error
  /// عشان الشاشة تعرض "مفيش نتايج" بدل ما تقع
  Future<List<PlaceResult>> search(String query, {String? countryCode}) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    try {
      final uri = Uri.https(_base, '/search', {
        'q': trimmed,
        'format': 'json',
        'limit': '8',
        'addressdetails': '1',
        'accept-language': 'ar',
        // بيحصر النتايج في دولة المغسلة لو متعرفة، بيقلل النتايج الغلط
        // بنتأكد إنه كود ISO حرفين، عشان كود غلط مايرجعش نتايج فاضية
        if (countryCode != null && countryCode.length == 2)
          'countrycodes': countryCode.toLowerCase(),
      });

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) return const [];

      return decoded
          .map(_parseResult)
          .whereType<PlaceResult>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// بيحول الإحداثيات لعنوان مقروء بعد ما اليوزر يحرك الدبوس
  /// بيرجع null لو فشل، والشاشة ساعتها بتعرض الإحداثيات نفسها
  Future<String?> reverse(double latitude, double longitude) async {
    try {
      final uri = Uri.https(_base, '/reverse', {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'accept-language': 'ar',
      });

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return null;

      final name = decoded['display_name'];
      return (name is String && name.trim().isNotEmpty) ? name : null;
    } catch (_) {
      return null;
    }
  }

  PlaceResult? _parseResult(dynamic item) {
    if (item is! Map) return null;

    final lat = double.tryParse('${item['lat']}');
    final lon = double.tryParse('${item['lon']}');
    final name = item['display_name'];

    if (lat == null || lon == null || name is! String) return null;

    return PlaceResult(displayName: name, latitude: lat, longitude: lon);
  }

  void dispose() => _client.close();
}
