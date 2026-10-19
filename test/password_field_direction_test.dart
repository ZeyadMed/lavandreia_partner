import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';

const _passwordKey = Key('password');
const _nameKey = Key('name');

void main() {
  late TextEditingController password;
  late TextEditingController name;

  setUp(() {
    password = TextEditingController();
    name = TextEditingController();
  });

  tearDown(() {
    password.dispose();
    name.dispose();
  });

  /// الشاشة عربي (RTL) وفيها خانة باسورد وخانة عادية للمقارنة
  Future<void> pumpFields(WidgetTester tester, {bool obscure = false}) {
    tester.view.physicalSize = const Size(1125, 2436);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Column(
                children: [
                  Customtextfield(
                    key: _passwordKey,
                    hintText: 'password',
                    textEditingController: password,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: obscure,
                  ),
                  Customtextfield(
                    key: _nameKey,
                    hintText: 'name',
                    textEditingController: name,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder editableIn(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

  /// مكان الحرف رقم [index] أفقياً جوه الخانة بعد الرسم
  double charLeft(WidgetTester tester, Key key, int index) {
    final RenderEditable render = tester
        .state<EditableTextState>(editableIn(key))
        .renderEditable;
    return render
        .getBoxesForSelection(
          TextSelection(baseOffset: index, extentOffset: index + 1),
        )
        .first
        .left;
  }

  testWidgets('خانة الباسورد LTR والخانات العادية ماشية مع اتجاه الشاشة', (
    tester,
  ) async {
    await pumpFields(tester);

    expect(
      tester.widget<EditableText>(editableIn(_passwordKey)).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester.widget<EditableText>(editableIn(_nameKey)).textDirection,
      isNull,
    );
  });

  testWidgets('الباسورد بيظهر بنفس ترتيب الكتابة حتى والشاشة عربي', (
    tester,
  ) async {
    await pumpFields(tester);
    const typed = 'abc123!';
    await tester.enterText(editableIn(_passwordKey), typed);
    await tester.enterText(editableIn(_nameKey), typed);
    await tester.pump();

    final bang = typed.indexOf('!');

    // في خانة الباسورد: الحرف الأول على الشمال والرمز في الآخر على اليمين
    expect(
      charLeft(tester, _passwordKey, 0),
      lessThan(charLeft(tester, _passwordKey, bang)),
    );
    // للمقارنة: في الخانة العادية العربي الـ ! بتتنقل لأول السطر (الشمال)
    expect(
      charLeft(tester, _nameKey, bang),
      lessThan(charLeft(tester, _nameKey, 0)),
    );
  });

  testWidgets('الاتجاه مايتغيرش لما الباسورد يتخفى أو يظهر', (tester) async {
    await pumpFields(tester, obscure: true);
    expect(
      tester.widget<EditableText>(editableIn(_passwordKey)).textDirection,
      TextDirection.ltr,
    );

    await pumpFields(tester, obscure: false);
    expect(
      tester.widget<EditableText>(editableIn(_passwordKey)).textDirection,
      TextDirection.ltr,
    );
  });
}
