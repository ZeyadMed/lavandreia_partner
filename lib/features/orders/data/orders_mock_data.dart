import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';

/// بيانات مؤقتة لحد ما الـ API يجهز
/// نفس الطلبات اللي في الديزاين بالظبط
abstract final class OrdersMockData {
  /// صور القطع، لينكات حقيقية من Unsplash لحد ما السيرفر يرجّع صور المنتجات
  /// الأبعاد مصغّرة عشان تحمّل بسرعة في الليستة
  static const String _shirt =
      'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=200&q=70';
  static const String _pants =
      'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=200&q=70';
  static const String _jacket =
      'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=200&q=70';
  static const String _dress =
      'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=200&q=70';
  static const String _blouse =
      'https://images.unsplash.com/photo-1564257631407-4deb1f99d992?w=200&q=70';
  static const String _suit =
      'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=200&q=70';
  static const String _carpet =
      'https://images.unsplash.com/photo-1600166898405-da9535204843?w=200&q=70';
  static const String _curtain =
      'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=200&q=70';
  static const String _bedSheet =
      'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=200&q=70';
  static const String _blanket =
      'https://images.unsplash.com/photo-1616627561950-9f746e330187?w=200&q=70';

  /// التواريخ محسوبة نسبة للنهاردة عشان الكروت تفضل تقول "اليوم / أمس"
  static DateTime _at({int daysAgo = 0, required int hour, int minute = 0}) {
    final now = DateTime.now();
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysAgo));
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static List<PartnerOrder> get all => [
    PartnerOrder(
      number: 'ORD-10245',
      customerName: 'أحمد محمد',
      customerPhone: '0501234567',
      items: const [
        PartnerOrderItem(
          name: 'قميص',
          quantity: 1,
          serviceKey: 'service_wash_iron',
          imageUrl: _shirt,
        ),
        PartnerOrderItem(
          name: 'بنطلون',
          quantity: 2,
          serviceKey: 'service_wash_iron',
          imageUrl: _pants,
        ),
        PartnerOrderItem(
          name: 'جاكيت',
          quantity: 1,
          serviceKey: 'service_dry_clean',
          imageUrl: _jacket,
        ),
      ],
      address: 'مدينة نصر، القاهرة',
      createdAt: _at(hour: 10, minute: 45),
      total: 85,
      status: PartnerOrderStatus.inProgress,
      distanceKm: 2.3,
      estimatedHours: 4,
      stage: PartnerOrderStage.pickedUp,
    ),
    PartnerOrder(
      number: 'ORD-10244',
      customerName: 'سارة العلي',
      customerPhone: '0555678901',
      items: const [
        PartnerOrderItem(
          name: 'فستان',
          quantity: 2,
          serviceKey: 'service_dry_clean',
          imageUrl: _dress,
        ),
        PartnerOrderItem(
          name: 'بلوزة',
          quantity: 3,
          serviceKey: 'service_wash_iron',
          imageUrl: _blouse,
        ),
      ],
      address: 'المعادي، القاهرة',
      createdAt: _at(daysAgo: 1, hour: 15, minute: 20),
      total: 120,
      status: PartnerOrderStatus.ready,
      distanceKm: 5.1,
      estimatedHours: 2,
      stage: PartnerOrderStage.ready,
    ),
    PartnerOrder(
      number: 'ORD-10243',
      customerName: 'محمد خالد',
      customerPhone: '0533445566',
      items: const [
        PartnerOrderItem(
          name: 'بدلة',
          quantity: 1,
          serviceKey: 'service_dry_clean',
          imageUrl: _suit,
        ),
      ],
      address: 'الزمالك، القاهرة',
      createdAt: _at(daysAgo: 1, hour: 11),
      total: 150,
      status: PartnerOrderStatus.completed,
      distanceKm: 8.4,
      estimatedHours: 24,
      stage: PartnerOrderStage.delivered,
    ),
    PartnerOrder(
      number: 'ORD-10242',
      customerName: 'فاطمة حسن',
      customerPhone: '0522334455',
      items: const [
        PartnerOrderItem(
          name: 'سجادة',
          quantity: 1,
          serviceKey: 'service_wash_carpet',
          imageUrl: _carpet,
        ),
      ],
      address: 'الدقي، الجيزة',
      createdAt: _at(daysAgo: 1, hour: 9, minute: 30),
      total: 200,
      status: PartnerOrderStatus.rejected,
      distanceKm: 6.7,
      estimatedHours: 48,
      stage: PartnerOrderStage.placed,
    ),
    PartnerOrder(
      number: 'ORD-10241',
      customerName: 'عمر إبراهيم',
      customerPhone: '0511223344',
      items: const [
        PartnerOrderItem(
          name: 'ستارة',
          quantity: 4,
          serviceKey: 'service_clean_curtains',
          imageUrl: _curtain,
        ),
        PartnerOrderItem(
          name: 'مفرش',
          quantity: 2,
          serviceKey: 'service_clean_bedding',
          imageUrl: _bedSheet,
        ),
      ],
      address: 'مصر الجديدة، القاهرة',
      createdAt: _at(daysAgo: 2, hour: 13, minute: 15),
      total: 310,
      status: PartnerOrderStatus.newOrder,
      distanceKm: 3.9,
      estimatedHours: 12,
      stage: PartnerOrderStage.placed,
    ),
    PartnerOrder(
      number: 'ORD-10240',
      customerName: 'ليلى سعيد',
      customerPhone: '0599887766',
      items: const [
        PartnerOrderItem(
          name: 'بطانية',
          quantity: 2,
          serviceKey: 'service_wash_blankets',
          imageUrl: _blanket,
        ),
        PartnerOrderItem(
          name: 'ملاءة',
          quantity: 3,
          serviceKey: 'service_clean_bedding',
          imageUrl: _bedSheet,
        ),
      ],
      address: 'الشيخ زايد، الجيزة',
      createdAt: _at(daysAgo: 3, hour: 17, minute: 40),
      total: 175,
      status: PartnerOrderStatus.completed,
      distanceKm: 11.2,
      estimatedHours: 24,
      stage: PartnerOrderStage.delivered,
    ),
  ];

  /// آخر 3 طلبات اللي بتظهر في الرئيسية
  static List<PartnerOrder> get latest => all.take(3).toList();

  /// إحصائيات الكروت الثلاثة فوق في الرئيسية
  /// رقم "مكتملة اليوم" جاي من السيرفر في الحقيقة (بيشمل طلبات اتقفلت
  /// النهاردة حتى لو اتعملت من يومين)، فمثبتينه زي الديزاين مؤقتاً
  static const int completedTodayCount = 3;

  static int get inProgressCount => all
      .where((order) => order.status == PartnerOrderStatus.inProgress)
      .length;

  static int get newOrdersCount =>
      all.where((order) => order.status == PartnerOrderStatus.newOrder).length;
}
