import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/profile/data/working_hours_data_source.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/working_hours_screen.dart';

/// سيرفر وهمي بيخزن اللي بيتبعت في الـ PUT ويرجّعه في الـ GET بنفس شكل الباك
class _FakeServer implements WorkingHoursDataSource {
  List<Map<String, dynamic>> stored;
  int gets = 0;
  final List<List<Map<String, dynamic>>> puts = [];

  _FakeServer(this.stored);

  @override
  Future<Either<Failure, List<WorkingDay>>> getWorkingHours() async {
    gets++;
    return Right(stored.map(WorkingDay.fromJson).toList());
  }

  @override
  Future<Either<Failure, void>> updateWorkingHours(
    List<WorkingDay> days,
  ) async {
    final body = days.map((day) => day.toJson()).toList();
    puts.add(body);
    stored = body;
    return const Right(null);
  }
}

Map<String, dynamic> openDay(String day, String from, String to) => {
  'dayOfWeek': day,
  'openTime': from,
  'closeTime': to,
  'isClosed': false,
};

/// ترتيب السويتشات في الصفحة من السبت للجمعة
int switchIndex(String key) => WorkingDay.weekDays.indexOf(key);

void main() {
  late _FakeServer server;

  setUp(() {
    server = _FakeServer([
      openDay('Saturday', '08:30:00', '23:15:00'),
      openDay('Monday', '09:00:00', '12:00:00'),
      openDay('Thursday', '21:00:00', '02:00:00'),
    ]);
    getIt.registerSingleton<WorkingHoursDataSource>(server);
  });

  tearDown(() => getIt.reset());

  /// الصفحة بتتفتح بـ push عشان نقدر نجرب الرجوع منها
  Future<void> openScreen(WidgetTester tester) async {
    // طويلة كفاية إن الأيام السبعة تبان من غير scroll
    tester.view.physicalSize = const Size(1125, 9000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 3000),
        builder: (_, _) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkingHoursScreen(),
                    ),
                  ),
                  child: const Text('open hours'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open hours'));
    await tester.pumpAndSettle();
  }

  bool isDayOn(WidgetTester tester, String key) =>
      tester.widget<Switch>(find.byType(Switch).at(switchIndex(key))).value;

  Future<void> toggleDay(WidgetTester tester, String key) async {
    await tester.tap(find.byType(Switch).at(switchIndex(key)));
    await tester.pumpAndSettle();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('shows AM/PM with noon and next-day hints', (tester) async {
    await openScreen(tester);

    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('11:15 PM'), findsOneWidget);
    // الاتنين بيقفل الظهر مش منتصف الليل
    expect(find.text('12:00 PM'), findsOneWidget);
    expect(find.text('noon'), findsOneWidget);
    // الخميس بيعدي منتصف الليل
    expect(find.text('9:00 PM'), findsOneWidget);
    expect(find.text('2:00 AM'), findsOneWidget);
    expect(find.text('next_day'), findsOneWidget);
  });

  testWidgets('the switch is on for open days and off for closed days', (
    tester,
  ) async {
    await openScreen(tester);

    expect(isDayOn(tester, 'saturday'), isTrue);
    expect(isDayOn(tester, 'thursday'), isTrue);
    // الجمعة مش راجعة من السيرفر فبتتعرض مقفولة
    expect(isDayOn(tester, 'friday'), isFalse);

    await toggleDay(tester, 'saturday');
    expect(isDayOn(tester, 'saturday'), isFalse);
    expect(find.text('8:30 AM'), findsNothing);
  });

  testWidgets('turning a day off and on keeps its hours', (tester) async {
    await openScreen(tester);

    await toggleDay(tester, 'saturday');
    await toggleDay(tester, 'saturday');

    expect(find.text('8:30 AM'), findsOneWidget);
    expect(find.text('11:15 PM'), findsOneWidget);
  });

  testWidgets('saved hours are sent, re-read, and shown the same on return', (
    tester,
  ) async {
    await openScreen(tester);
    expect(server.gets, 1);

    await toggleDay(tester, 'saturday');
    await toggleDay(tester, 'friday');
    await tester.tap(find.text('save_changes'));
    await tester.pumpAndSettle();

    expect(server.puts, hasLength(1));
    final sent = {for (final day in server.puts.single) day['dayOfWeek']: day};
    expect(sent['Saturday'], {'dayOfWeek': 'Saturday', 'isClosed': true});
    // الجمعة اتفتحت بالمواعيد الافتراضية
    expect(sent['Friday'], {
      'dayOfWeek': 'Friday',
      'isClosed': false,
      'openTime': '09:00:00',
      'closeTime': '22:00:00',
    });
    expect(sent['Thursday'], {
      'dayOfWeek': 'Thursday',
      'isClosed': false,
      'openTime': '21:00:00',
      'closeTime': '02:00:00',
    });
    // بعد الحفظ بيجيب من السيرفر تاني عشان المعروض يبقى المتسجل
    expect(server.gets, 2);

    // مفيش تعديلات فالرجوع مابيسألش
    await goBack(tester);
    expect(find.text('open hours'), findsOneWidget);

    await tester.tap(find.text('open hours'));
    await tester.pumpAndSettle();
    expect(server.gets, 3);
    expect(isDayOn(tester, 'saturday'), isFalse);
    expect(isDayOn(tester, 'friday'), isTrue);
    expect(find.text('9:00 PM'), findsOneWidget);
    expect(find.text('2:00 AM'), findsOneWidget);
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    await openScreen(tester);
    await toggleDay(tester, 'saturday');

    await goBack(tester);
    expect(find.text('unsaved_changes'), findsOneWidget);

    await tester.tap(find.text('stay'));
    await tester.pumpAndSettle();
    expect(find.text('unsaved_changes'), findsNothing);
    expect(find.byType(WorkingHoursScreen), findsOneWidget);

    await goBack(tester);
    await tester.tap(find.text('leave_without_saving'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkingHoursScreen), findsNothing);
    expect(server.puts, isEmpty);
  });

  testWidgets('same open and close time is not sent', (tester) async {
    server.stored = [openDay('Monday', '09:00:00', '09:00:00')];
    await openScreen(tester);

    await tester.tap(find.text('save_changes'));
    await tester.pumpAndSettle();

    expect(find.text('open_close_same_time'), findsOneWidget);
    expect(server.puts, isEmpty);
  });

  testWidgets('close time picker warns when it ends the next day', (
    tester,
  ) async {
    await openScreen(tester);

    await tester.tap(find.text('2:00 AM'));
    await tester.pumpAndSettle();

    // في الكارت وفي معاينة البوتوم شيت
    expect(find.text('2:00 AM'), findsNWidgets(2));
    expect(find.text('next_day'), findsNWidgets(2));
  });

  testWidgets('status banner shows open or closed now', (tester) async {
    await openScreen(tester);

    expect(
      find.text('open_now').evaluate().length +
          find.text('closed_now').evaluate().length,
      1,
    );
    expect(find.text('working_status_note'), findsOneWidget);
  });
}
