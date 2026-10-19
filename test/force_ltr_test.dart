import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/core/extensions/string_extension.dart';

/// مكان أول حرف [char] أفقياً بعد ما النص يترسم في سطر [direction]
double _charLeft(String text, String char, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(text: text),
    textDirection: direction,
  )..layout();
  final index = text.indexOf(char);
  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: index, extentOffset: index + 1),
  );
  painter.dispose();
  return boxes.first.left;
}

void main() {
  const phone = '+218911234567';

  test('من غير forceLtr الـ + بتتنقل لآخر الرقم في العربي', () {
    final plus = _charLeft(phone, '+', TextDirection.rtl);
    final lastDigit = _charLeft(phone, '7', TextDirection.rtl);
    expect(plus, greaterThan(lastDigit));
  });

  test('forceLtr بيخلي الـ + على شمال الرقم في العربي', () {
    final text = phone.forceLtr;
    final plus = _charLeft(text, '+', TextDirection.rtl);
    final lastDigit = _charLeft(text, '7', TextDirection.rtl);
    expect(plus, lessThan(lastDigit));
  });

  test('forceLtr بيظبط الرقم وهو جنب كلام عربي في نفس السطر', () {
    final text = 'أحمد • ${phone.forceLtr}';
    final plus = _charLeft(text, '+', TextDirection.rtl);
    final lastDigit = _charLeft(text, '7', TextDirection.rtl);
    final name = _charLeft(text, 'أ', TextDirection.rtl);
    expect(plus, lessThan(lastDigit));
    // الاسم لسه في أول السطر العربي (على اليمين)
    expect(name, greaterThan(lastDigit));
  });

  test('forceLtr مابيغيرش النص الفاضي', () {
    expect(''.forceLtr, isEmpty);
  });
}
