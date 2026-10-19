import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';

/// المغاسل كلها في ليبيا، وتوقيتها UTC+2 طول السنة من غير توقيت صيفي
/// فبنحسب بيه مش بتوقيت الجهاز، عشان الحالة تفضل صح لو الموبايل متظبط على توقيت تاني
const Duration laundryUtcOffset = Duration(hours: 2);

/// الساعة دلوقتي بتوقيت المغسلة، كـ DateTime بعلامة UTC وأرقامه هي الساعة المحلية
DateTime laundryNow() => DateTime.now().toUtc().add(laundryUtcOffset);

/// حالة المغسلة "مفتوح الآن / مغلق الآن" في لحظة معينة حسب مواعيد عملها
class WorkingHoursStatus {
  /// مفاتيح الأيام بترتيب DateTime.weekday، الاتنين = 1 لحد الحد = 7
  static const _keysByWeekday = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final bool isOpen;

  /// لو مفتوحة: وقت القفل، ولو مقفولة: أقرب وقت فتح
  /// و null لو مفيش ولا يوم شغل في الأسبوع
  final DateTime? changesAt;

  const WorkingHoursStatus({required this.isOpen, this.changesAt});

  /// مفتاح اليوم زي 'friday'، نفس مفاتيح [WorkingDay.weekDays] والترجمة
  static String weekdayKey(DateTime date) => _keysByWeekday[date.weekday - 1];

  /// [now] لازم يكون بتوقيت المغسلة، زي [laundryNow]
  /// كل دوام بيتحسب لليوم اللي بيبدأ فيه، فدوام الخميس 9:00 PM لـ 2:00 AM
  /// بيفضل مفتوح لحد 2 الفجر يوم الجمعة حتى لو الجمعة نفسها أجازة
  /// الفتح داخل في الدوام والقفل لأ، فالمغسلة اللي بتقفل 10:00 PM مقفولة الساعة 10:00 بالظبط
  factory WorkingHoursStatus.at(List<WorkingDay> days, DateTime now) {
    // بنشتغل بأرقام الساعة بس، عشان التوقيت الصيفي بتاع الجهاز مايأثرش
    final time = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
    final shifts = _shiftsAround(days, time);

    for (var i = 0; i < shifts.length; i++) {
      final (start, end) = shifts[i];
      if (time.isBefore(start) || !time.isBefore(end)) continue;

      // لو الدوام اللي بعده بيبدأ أول ما ده يخلص، المغسلة مابتقفلش في النص
      var closesAt = end;
      for (final (nextStart, nextEnd) in shifts.skip(i + 1)) {
        if (nextStart.isAfter(closesAt)) break;
        if (nextEnd.isAfter(closesAt)) closesAt = nextEnd;
      }
      return WorkingHoursStatus(isOpen: true, changesAt: closesAt);
    }

    final nextOpen = shifts
        .map((shift) => shift.$1)
        .where((start) => start.isAfter(time))
        .firstOrNull;
    return WorkingHoursStatus(isOpen: false, changesAt: nextOpen);
  }

  /// الدوامات من امبارح (ممكن يكون لسه شغال بعد منتصف الليل) لحد أسبوع قدام
  /// (عشان أقرب فتح)، مترتبة بوقت البداية
  static List<(DateTime, DateTime)> _shiftsAround(
    List<WorkingDay> days,
    DateTime time,
  ) {
    final byKey = {for (final day in days) day.key: day};
    return [
      for (var offset = -1; offset <= 7; offset++)
        ?_shiftOn(
          byKey,
          DateTime.utc(time.year, time.month, time.day + offset),
        ),
    ];
  }

  static (DateTime, DateTime)? _shiftOn(
    Map<String, WorkingDay> byKey,
    DateTime date,
  ) {
    final day = byKey[weekdayKey(date)];
    if (day == null || day.isClosed || !day.isValid) return null;

    final start = date.add(Duration(minutes: day.openTime!.minutesOfDay));
    var end = date.add(Duration(minutes: day.closeTime!.minutesOfDay));
    if (day.endsNextDay) end = end.add(const Duration(days: 1));
    return (start, end);
  }
}
