import 'package:flutter/foundation.dart';

/// أرقام التابات في الـ bottom nav عشان منستخدمش أرقام سايبة في الكود
abstract final class BottomNavTab {
  static const int home = 0;
  static const int orders = 1;
  static const int services = 2;
  static const int profile = 3;
}

/// بيخلي أي شاشة جوه الـ bottom nav تقدر تودّي المستخدم لتاب تاني
/// زي "عرض الكل" في الرئيسية اللي بيفتح تاب الطلبات
class BottomNavController extends ValueNotifier<int> {
  BottomNavController() : super(BottomNavTab.home);

  /// الإنستانس الوحيد اللي الـ BottomNavApp بيسمع عليه
  static final BottomNavController instance = BottomNavController();

  void goTo(int index) => value = index;
}
