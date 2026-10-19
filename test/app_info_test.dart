import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/features/profile/data/app_info_data_source.dart';
import 'package:lavanderia_partner/features/profile/data/models/privacy_policy.dart';
import 'package:lavanderia_partner/features/profile/data/models/support_contacts.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/privacy_policy_screen.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/support_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نفس الـ data اللي بترجع من api/auth/contacts و api/auth/privacy-policy
const _contactsJson = {
  'phoneNumber1': '012546465466',
  'phoneNumber2': '012123358666',
  'email': 'ahmed@gmail.commm',
};

const _privacyJson = {
  'content':
      '<h1>string</h1><p><span style="font-size: 13px;">string</span></p>'
      '<p><span style="font-size: 13px;">gggggggggggg</span></p>',
  'updatedAt': '2026-09-29T14:28:34.2468157',
};

/// سيرفر وهمي بيرد بالترتيب من [contacts] و [policies]، والـ null معناه فشل
class _FakeAppInfo implements AppInfoDataSource {
  final List<Map<String, dynamic>?> contacts;
  final List<Map<String, dynamic>?> policies;
  int contactsCalls = 0;
  int policyCalls = 0;

  _FakeAppInfo({this.contacts = const [], this.policies = const []});

  @override
  Future<Either<Failure, SupportContacts>> getContacts() async {
    final json = contacts[contactsCalls++];
    if (json == null) return Left(ServerFailure(message: 'boom'));
    return Right(SupportContacts.fromJson(json));
  }

  @override
  Future<Either<Failure, PrivacyPolicy>> getPrivacyPolicy() async {
    final json = policies[policyCalls++];
    if (json == null) return Left(ServerFailure(message: 'boom'));
    return Right(PrivacyPolicy.fromJson(json));
  }
}

void main() {
  group('SupportContacts.fromJson', () {
    test('reads the three contacts from the response', () {
      final contacts = SupportContacts.fromJson(_contactsJson);

      expect(contacts.phoneNumber1, '012546465466');
      expect(contacts.phoneNumber2, '012123358666');
      expect(contacts.email, 'ahmed@gmail.commm');
      expect(contacts.isEmpty, isFalse);
    });

    test('missing or null values become empty and get trimmed', () {
      final contacts = SupportContacts.fromJson({
        'phoneNumber1': ' 0911234567 ',
        'phoneNumber2': null,
      });

      expect(contacts.phoneNumber1, '0911234567');
      expect(contacts.phoneNumber2, '');
      expect(contacts.email, '');
      expect(SupportContacts.fromJson({}).isEmpty, isTrue);
    });
  });

  group('PrivacyPolicy.fromJson', () {
    test('keeps the HTML and parses the 7-digit fraction date', () {
      final policy = PrivacyPolicy.fromJson(_privacyJson);

      expect(policy.content, startsWith('<h1>string</h1>'));
      expect(policy.updatedAt, DateTime(2026, 9, 29, 14, 28, 34, 246, 815));
    });

    test('a missing or broken date is null', () {
      expect(PrivacyPolicy.fromJson({'content': 'x'}).updatedAt, isNull);
      expect(
        PrivacyPolicy.fromJson({'content': 'x', 'updatedAt': 'nope'}).updatedAt,
        isNull,
      );
    });
  });

  group('SupportScreen', () {
    tearDown(() => getIt.reset());

    Future<_FakeAppInfo> openScreen(
      WidgetTester tester,
      List<Map<String, dynamic>?> responses,
    ) async {
      final fake = _FakeAppInfo(contacts: responses);
      getIt.registerSingleton<AppInfoDataSource>(fake);
      tester.view.physicalSize = const Size(1125, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 2000),
          builder: (_, _) => const MaterialApp(home: SupportScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('shows the contacts from the API', (tester) async {
      await openScreen(tester, [_contactsJson]);

      expect(find.text('contact_us'), findsOneWidget);
      expect(find.text('012546465466'), findsOneWidget);
      expect(find.text('012123358666'), findsOneWidget);
      expect(find.text('ahmed@gmail.commm'), findsOneWidget);
      // الواتساب اتشال لأن الـ API مابيرجعش رقم واتساب
      expect(find.text('contact_by_whatsapp'), findsNothing);
    });

    testWidgets('hides empty values, and the section when all are empty', (
      tester,
    ) async {
      await openScreen(tester, [
        {'phoneNumber1': '0911234567', 'phoneNumber2': '', 'email': ''},
      ]);
      expect(find.text('0911234567'), findsOneWidget);
      expect(find.text('contact_by_phone_alt'), findsNothing);
      expect(find.text('contact_by_email'), findsNothing);

      await getIt.reset();
      await tester.pumpWidget(const SizedBox());
      await openScreen(tester, [{}]);
      expect(find.text('contact_us'), findsNothing);
      // الأسئلة الشائعة ثابتة وبتفضل ظاهرة
      expect(find.text('faq'), findsOneWidget);
    });

    testWidgets('a failure shows retry, and retry loads the contacts', (
      tester,
    ) async {
      final fake = await openScreen(tester, [null, _contactsJson]);

      expect(find.text('contacts_load_failed'), findsOneWidget);
      expect(find.text('faq'), findsOneWidget);

      await tester.tap(find.text('try_again'));
      await tester.pumpAndSettle();

      expect(fake.contactsCalls, 2);
      expect(find.text('contacts_load_failed'), findsNothing);
      expect(find.text('012546465466'), findsOneWidget);
    });
  });

  group('PrivacyPolicyScreen', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    tearDown(() => getIt.reset());

    /// بالعربي الحقيقي عشان نتأكد من شكل تاريخ آخر تحديث
    Future<_FakeAppInfo> openScreen(
      WidgetTester tester,
      List<Map<String, dynamic>?> responses,
    ) async {
      final fake = _FakeAppInfo(policies: responses);
      getIt.registerSingleton<AppInfoDataSource>(fake);
      await tester.runAsync(
        () => tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            path: 'assets/translations',
            startLocale: const Locale('ar'),
            fallbackLocale: const Locale('ar'),
            useOnlyLangCode: true,
            saveLocale: false,
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (context, _) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const PrivacyPolicyScreen(),
              ),
            ),
          ),
        ),
      );
      // الترجمة بتتحمل من الأصول async، فبنستناها لحد ما الشاشة تظهر
      for (var i = 0; i < 20 && find.byType(Scaffold).evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('renders the HTML and the server date', (tester) async {
      await openScreen(tester, [_privacyJson]);

      expect(find.text('سياسة الخصوصية'), findsOneWidget);
      expect(
        find.textContaining('gggggggggggg', findRichText: true),
        findsOneWidget,
      );
      // التاج نفسه مايظهرش كنص
      expect(find.textContaining('<h1>', findRichText: true), findsNothing);
      // الأرقام بالهندي زي باقي التواريخ في التطبيق بالعربي
      expect(
        find.text('آخر تحديث: ٢٩ سبتمبر ٢٠٢٦'),
        findsOneWidget,
      );
    });

    testWidgets('a failure shows retry, and retry loads the policy', (
      tester,
    ) async {
      final fake = await openScreen(tester, [null, _privacyJson]);

      expect(find.text('تعذر تحميل سياسة الخصوصية'), findsOneWidget);

      await tester.tap(find.text('حاول مرة أخرى'));
      await tester.pumpAndSettle();

      expect(fake.policyCalls, 2);
      expect(
        find.textContaining('gggggggggggg', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
