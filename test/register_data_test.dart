import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/features/auth/register/data/locations_data_source.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';

void main() {
  group('SelectedService price', () {
    test('سعر صحيح بيعدي', () {
      final service = SelectedService(
        id: 'a',
        name: 'غسيل',
        emoji: '👔',
        price: '12.5',
      );
      expect(service.hasValidPrice, isTrue);
      expect(service.priceValue, 12.5);
    });

    test('سعر فاضي أو صفر مابيعديش', () {
      for (final price in ['', '0', '  ', 'abc']) {
        final service = SelectedService(
          id: 'a',
          name: 'غسيل',
          emoji: '👔',
          price: price,
        );
        expect(service.hasValidPrice, isFalse, reason: 'price="$price"');
      }
    });
  });

  group('WorkingDay', () {
    test('اليوم المقفول صحيح من غير ساعات', () {
      expect(WorkingDay(key: 'friday', isClosed: true).isValid, isTrue);
    });

    test('اليوم المفتوح لازم ساعتين', () {
      expect(WorkingDay(key: 'saturday').isValid, isFalse);
      expect(
        WorkingDay(
          key: 'saturday',
          openTime: const DateTimeRangePart(hour: 9, minute: 0),
        ).isValid,
        isFalse,
      );
      expect(
        WorkingDay(
          key: 'saturday',
          openTime: const DateTimeRangePart(hour: 9, minute: 0),
          closeTime: const DateTimeRangePart(hour: 22, minute: 0),
        ).isValid,
        isTrue,
      );
    });

    test('صيغة الوقت للسيرفر وللعرض', () {
      const morning = DateTimeRangePart(hour: 9, minute: 5);
      expect(morning.toApiString(), '09:05');
      expect(morning.toDisplayString(), '9:05 ص');

      const evening = DateTimeRangePart(hour: 22, minute: 0);
      expect(evening.toApiString(), '22:00');
      expect(evening.toDisplayString(), '10:00 م');

      // منتصف الليل والظهر، الحالتين اللي بيغلط فيهم تحويل 12 ساعة
      expect(const DateTimeRangePart(hour: 0, minute: 0).toDisplayString(),
          '12:00 ص');
      expect(const DateTimeRangePart(hour: 12, minute: 30).toDisplayString(),
          '12:30 م');
    });

    test('ليبلز ص/م بتتبعت من بره', () {
      expect(
        const DateTimeRangePart(hour: 9, minute: 5)
            .toDisplayString(amLabel: 'AM', pmLabel: 'PM'),
        '9:05 AM',
      );
      expect(
        const DateTimeRangePart(hour: 22, minute: 0)
            .toDisplayString(amLabel: 'AM', pmLabel: 'PM'),
        '10:00 PM',
      );
    });

    test('التحويل بين 24 ساعة و 12 ساعة + ص/م يرجع نفس القيمة', () {
      // نفس المنطق اللي البوتوم شيت بيعمله، بنتأكد إنه ملفش دورة
      for (var hour = 0; hour < 24; hour++) {
        final isAm = hour < 12;
        final hour12 = hour % 12 == 0 ? 12 : hour % 12;

        var roundTripped = hour12 % 12;
        if (!isAm) roundTripped += 12;

        expect(roundTripped, hour, reason: 'hour=$hour');
      }
    });
  });

  group('RegisterData.toJson', () {
    RegisterData buildData() => RegisterData()
      ..laundryName = 'مغسلة المدينة'
      ..ownerName = 'محمد أحمد'
      ..ownerPhone = '+218911234567'
      ..password = 'password123'
      ..countryId = 'LY'
      ..cityId = 'LY-TIP'
      ..areaName = 'حي الأندلس'
      ..laundryPhone = '+218921234567'
      ..latitude = 32.8872
      ..longitude = 13.1913
      ..selectedServices = [
        SelectedService(id: 'wash', name: 'غسيل', emoji: '👔', price: '10'),
      ]
      ..workingDays = [
        WorkingDay(
          key: 'saturday',
          openTime: const DateTimeRangePart(hour: 9, minute: 0),
          closeTime: const DateTimeRangePart(hour: 22, minute: 0),
        ),
        WorkingDay(key: 'friday', isClosed: true),
      ];

    test('البريد الاختياري بيتشال لما يبقى فاضي', () {
      final json = buildData().toJson();
      expect(json.containsKey('email'), isFalse);
    });

    test('البريد بيتبعت لما يتكتب', () {
      final json = (buildData()..email = ' a@b.com ').toJson();
      expect(json['email'], 'a@b.com');
    });

    test('الإحداثيات والخدمات بتتبعت صح', () {
      final json = buildData().toJson();
      expect(json['latitude'], 32.8872);
      expect(json['longitude'], 13.1913);
      expect(json['services'], [
        {'service_id': 'wash', 'price': 10.0},
      ]);
    });

    test('اليوم المقفول مابيبعتش ساعات', () {
      final hours = buildData().toJson()['working_hours'] as List;
      expect(hours[0], {
        'day': 'saturday',
        'is_closed': false,
        'open_time': '09:00',
        'close_time': '22:00',
      });
      expect(hours[1], {'day': 'friday', 'is_closed': true});
    });
  });

  group('StaticLocationsDataSource', () {
    test('كل دولة ليها كود ISO حرفين ومدن', () async {
      final countries = await const StaticLocationsDataSource().getCountries();
      expect(countries, isNotEmpty);

      for (final country in countries) {
        // البحث على الخريطة بيعتمد على إن الكود حرفين بالظبط
        expect(country.isoCode.length, 2, reason: country.nameEn);
        expect(country.cities, isNotEmpty, reason: country.nameEn);
      }
    });

    test('معرفات المدن مفيش فيها تكرار', () async {
      final countries = await const StaticLocationsDataSource().getCountries();
      final ids = countries.expand((c) => c.cities).map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
