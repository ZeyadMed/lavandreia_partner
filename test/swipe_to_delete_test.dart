import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/swipe_to_delete.dart';

void main() {
  late ValueNotifier<Object?> openId;
  late List<int> deleted;

  setUp(() {
    openId = ValueNotifier<Object?>(null);
    deleted = [];
  });

  tearDown(() => openId.dispose());

  Future<void> pumpCards(WidgetTester tester, {bool enabled = true}) {
    // مقاس موبايل عادي عشان الـ ScreenUtil يحسب زي الأبلكيشن
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final id in [1, 2])
                  SwipeToDelete(
                    id: id,
                    openId: openId,
                    enabled: enabled,
                    onDelete: () async => deleted.add(id),
                    child: SizedBox(
                      key: ValueKey('card$id'),
                      height: 70,
                      width: double.infinity,
                      child: Text('card $id'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('swiping reveals delete without deleting', (tester) async {
    await pumpCards(tester);
    expect(find.text('delete'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('card1')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('delete'), findsOneWidget);
    expect(openId.value, 1);
    expect(deleted, isEmpty);
  });

  testWidgets('swiping right also reveals delete', (tester) async {
    await pumpCards(tester);

    await tester.drag(
      find.byKey(const ValueKey('card1')),
      const Offset(200, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('delete'), findsOneWidget);
    expect(deleted, isEmpty);
  });

  testWidgets('tapping delete calls onDelete then closes', (tester) async {
    await pumpCards(tester);
    await tester.drag(
      find.byKey(const ValueKey('card1')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();

    expect(deleted, [1]);
    expect(find.text('delete'), findsNothing);
    expect(openId.value, isNull);
  });

  testWidgets('a short slow drag snaps back closed', (tester) async {
    await pumpCards(tester);

    await tester.timedDrag(
      find.byKey(const ValueKey('card1')),
      const Offset(-20, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(find.text('delete'), findsNothing);
  });

  testWidgets('tapping an open card closes it', (tester) async {
    await pumpCards(tester);
    await tester.drag(
      find.byKey(const ValueKey('card1')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    // الطبقة اللي فوق الكارت المفتوح هي اللي بتاخد الضغطة، وده المقصود
    await tester.tap(find.text('card 1'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('delete'), findsNothing);
    expect(deleted, isEmpty);
  });

  testWidgets('opening a card closes the other one', (tester) async {
    await pumpCards(tester);
    await tester.drag(
      find.byKey(const ValueKey('card1')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('card2')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('delete'), findsOneWidget);
    expect(openId.value, 2);
  });

  testWidgets('disabled cards do not swipe', (tester) async {
    await pumpCards(tester, enabled: false);

    await tester.drag(
      find.byKey(const ValueKey('card1')),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('delete'), findsNothing);
  });
}
