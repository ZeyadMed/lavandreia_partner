import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/profile/data/working_hours_status.dart';

DateTimeRangePart t(int hour, [int minute = 0]) =>
    DateTimeRangePart(hour: hour, minute: minute);

WorkingDay open(String key, DateTimeRangePart from, DateTimeRangePart to) =>
    WorkingDay(key: key, openTime: from, closeTime: to);

/// أسبوع 19 أكتوبر 2026: الاتنين 19، الخميس 22، الجمعة 23، السبت 24
DateTime at(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, 10, day, hour, minute);

void main() {
  group('DateTimeRangePart display', () {
    test('12 PM is noon and 12 AM is midnight', () {
      expect(t(0).toDisplayString(), '12:00 AM');
      expect(t(12).toDisplayString(), '12:00 PM');
      expect(t(9, 5).toDisplayString(), '9:05 AM');
      expect(t(22).toDisplayString(), '10:00 PM');
      expect(t(23, 59).toDisplayString(), '11:59 PM');
    });

    test('only the 12 o\'clock hour gets a hint', () {
      expect(t(12).periodHintKey, 'noon');
      expect(t(12, 30).periodHintKey, 'noon');
      expect(t(0).periodHintKey, 'midnight');
      expect(t(0, 30).periodHintKey, 'after_midnight');
      expect(t(9).periodHintKey, isNull);
      expect(t(21).periodHintKey, isNull);
    });

    test('server TimeSpan round trips', () {
      final day = WorkingDay.fromJson({
        'dayOfWeek': 'Thursday',
        'openTime': '21:00:00',
        'closeTime': '02:00:00',
        'isClosed': false,
      });
      expect(day.key, 'thursday');
      expect(day.openTime, t(21));
      expect(day.closeTime, t(2));
      expect(day.toJson(), {
        'dayOfWeek': 'Thursday',
        'isClosed': false,
        'openTime': '21:00:00',
        'closeTime': '02:00:00',
      });
    });
  });

  group('WorkingDay', () {
    test('overnight shift is valid and ends the next day', () {
      final day = open('thursday', t(21), t(2));
      expect(day.isValid, isTrue);
      expect(day.endsNextDay, isTrue);
      expect(day.closeHintKeys, ['next_day']);
    });

    test('closing at 12:00 AM says midnight, not next day', () {
      final day = open('monday', t(9), t(0));
      expect(day.isValid, isTrue);
      expect(day.closeHintKeys, ['midnight']);
    });

    test('closing after midnight shows both hints', () {
      expect(open('monday', t(21), t(0, 30)).closeHintKeys, [
        'after_midnight',
        'next_day',
      ]);
    });

    test('closing at 12:00 PM is noon on the same day', () {
      final day = open('monday', t(9), t(12));
      expect(day.endsNextDay, isFalse);
      expect(day.closeHintKeys, ['noon']);
    });

    test('same open and close time is rejected', () {
      final day = open('monday', t(9), t(9));
      expect(day.hasSameOpenAndClose, isTrue);
      expect(day.isValid, isFalse);
    });

    test('closed day is valid without hours and keeps hours for reopening', () {
      final day = open('friday', t(9), t(22))..isClosed = true;
      expect(day.isValid, isTrue);
      expect(day.toJson(), {'dayOfWeek': 'Friday', 'isClosed': true});
      day.isClosed = false;
      expect(day.openTime, t(9));
    });

    test('hasSameHoursAs ignores hours of a closed day', () {
      final saved = WorkingDay(key: 'friday', isClosed: true);
      final edited = open('friday', t(9), t(22))..isClosed = true;
      expect(edited.hasSameHoursAs(saved), isTrue);
      edited.isClosed = false;
      expect(edited.hasSameHoursAs(saved), isFalse);
      expect(
        open('friday', t(9), t(22)).hasSameHoursAs(open('friday', t(9), t(23))),
        isFalse,
      );
    });
  });

  group('WorkingHoursStatus', () {
    final week = [
      open('monday', t(9), t(22)),
      open('tuesday', t(9), t(22)),
      open('thursday', t(21), t(2)),
      WorkingDay(key: 'friday', isClosed: true),
      WorkingDay(key: 'saturday', isClosed: true),
    ];

    WorkingHoursStatus statusAt(DateTime now) =>
        WorkingHoursStatus.at(week, now);

    test('open from the opening minute until just before closing', () {
      expect(statusAt(at(19, 8, 59)).isOpen, isFalse);
      expect(statusAt(at(19, 8, 59)).changesAt, at(19, 9));

      expect(statusAt(at(19, 9)).isOpen, isTrue);
      expect(statusAt(at(19, 21, 59)).isOpen, isTrue);
      expect(statusAt(at(19, 21, 59)).changesAt, at(19, 22));

      expect(statusAt(at(19, 22)).isOpen, isFalse);
      expect(statusAt(at(19, 22)).changesAt, at(20, 9));
    });

    test('overnight shift stays open after midnight on a day off', () {
      expect(statusAt(at(22, 20, 59)).isOpen, isFalse);
      expect(statusAt(at(22, 20, 59)).changesAt, at(22, 21));

      expect(statusAt(at(22, 23, 30)).isOpen, isTrue);
      expect(statusAt(at(22, 23, 30)).changesAt, at(23, 2));

      // الجمعة أجازة، بس دوام الخميس لسه شغال
      expect(statusAt(at(23, 0)).isOpen, isTrue);
      expect(statusAt(at(23, 1, 59)).isOpen, isTrue);

      expect(statusAt(at(23, 2)).isOpen, isFalse);
      // الجمعة والسبت أجازة والأحد مش متسجل، فأقرب فتح الاتنين
      expect(statusAt(at(23, 2)).changesAt, at(26, 9));
    });

    test('closing at 12:00 AM is open until midnight', () {
      final days = [open('monday', t(9), t(0))];
      expect(WorkingHoursStatus.at(days, at(19, 23, 59)).isOpen, isTrue);
      expect(WorkingHoursStatus.at(days, at(19, 23, 59)).changesAt, at(20, 0));
      expect(WorkingHoursStatus.at(days, at(20, 0)).isOpen, isFalse);
    });

    test('9 AM to 12 PM closes at noon, not midnight', () {
      final days = [open('monday', t(9), t(12))];
      expect(WorkingHoursStatus.at(days, at(19, 11, 59)).isOpen, isTrue);
      expect(WorkingHoursStatus.at(days, at(19, 12)).isOpen, isFalse);
      expect(WorkingHoursStatus.at(days, at(19, 23)).isOpen, isFalse);
    });

    test('back to back shifts report the final closing time', () {
      final days = [open('monday', t(18), t(0)), open('tuesday', t(0), t(3))];
      final status = WorkingHoursStatus.at(days, at(19, 23));
      expect(status.isOpen, isTrue);
      expect(status.changesAt, at(20, 3));
    });

    test('a laundry closed all week has no next opening', () {
      final days = [
        for (final key in WorkingDay.weekDays)
          WorkingDay(key: key, isClosed: true),
      ];
      final status = WorkingHoursStatus.at(days, at(19, 12));
      expect(status.isOpen, isFalse);
      expect(status.changesAt, isNull);
    });

    test('a day with the same open and close time is ignored', () {
      final days = [open('monday', t(9), t(9))];
      expect(WorkingHoursStatus.at(days, at(19, 9)).isOpen, isFalse);
    });

    test('local DateTime is read by its wall clock', () {
      final local = DateTime(2026, 10, 19, 21, 30);
      expect(WorkingHoursStatus.at(week, local).isOpen, isTrue);
    });

    test('laundryNow is Libya time, UTC+2', () {
      final diff = laundryNow().difference(DateTime.now().toUtc());
      expect(diff.inMinutes, closeTo(120, 1));
    });
  });
}
