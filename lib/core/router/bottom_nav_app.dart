import 'package:dio/dio.dart';
import 'package:lavanderia_partner/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lavanderia_partner/features/home/presentation/view/home_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/orders_screen.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/profile_screen.dart';
import 'package:lavanderia_partner/features/services/presentation/view/services_screen.dart';

class BottomNavApp extends StatefulWidget {
  const BottomNavApp({super.key});

  @override
  State<BottomNavApp> createState() => _BottomNavAppState();
}

class _BottomNavAppState extends State<BottomNavApp> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;
  final Map<int, Widget> _cachedPages = {};

  /// الترتيب زي الديزاين: الرئيسية - الطلبات - الخدمات - حسابي
  /// وفي العربي الصف بيتقلب لوحده فالرئيسية بتظهر على اليمين
  final List<_BottomNavItemData> _items = const [
    _BottomNavItemData(labelKey: 'home', icon: Icons.home_outlined),
    _BottomNavItemData(labelKey: 'my_orders', icon: Icons.task_alt_outlined),
    _BottomNavItemData(labelKey: 'services', icon: Icons.wb_sunny_outlined),
    _BottomNavItemData(labelKey: 'profile', icon: Icons.person_outline_rounded),
  ];

  @override
  void initState() {
    getIt<Dio>().options.headers['Accept-Language'] = 'ar';
    super.initState();
    // Only load home page initially
    _getPage(0);
  }

  Widget _getPage(int index) {
    if (_cachedPages.containsKey(index)) {
      return _cachedPages[index]!;
    }

    Widget page;
    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const OrdersScreen();
        break;
      case 2:
        page = const ServicesScreen();
        break;
      case 3:
        page = const ProfileScreen();
        break;
      default:
        page = const SizedBox.shrink();
    }

    _cachedPages[index] = page;
    return page;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _getPage(index);
    });
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    } else {
      final now = DateTime.now();
      if (_lastBackPressed == null ||
          now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
        _lastBackPressed = now;
        CustomErrorOverlay.show(context: context, text: "pressAgain".tr());
        return false;
      }
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldColor = isDarkMode
        ? const Color(0xFF111827)
        : AppColors.backgroundColor;

    final Color navBarColor = isDarkMode
        ? const Color(0xFF111827)
        : AppColors.whiteColor;
    final Color selectedItemColor = isDarkMode
        ? const Color(0xFF8EA2FF)
        : AppColors.primaryColor;
    final Color unselectedItemColor = isDarkMode
        ? const Color(0xFF8B95AA)
        : const Color(0xFF9AA0AC);

    // Build children list with only loaded pages
    final children = <Widget>[];
    for (int i = 0; i < _items.length; i++) {
      if (_cachedPages.containsKey(i)) {
        children.add(_cachedPages[i]!);
      } else {
        children.add(const SizedBox.shrink());
      }
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: scaffoldColor,
        body: IndexedStack(index: _selectedIndex, children: children),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBarColor,
            border: Border(
              top: BorderSide(
                color: isDarkMode ? Colors.white12 : const Color(0xFFE8ECF3),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(_items.length, (index) {
                final isSelected = _selectedIndex == index;
                final item = _items[index];
                final color = isSelected
                    ? selectedItemColor
                    : unselectedItemColor;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onItemTapped(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الشريط الصغير اللي فوق التاب المختار زي الديزاين
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          height: 3.h,
                          width: 28.w,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selectedItemColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(3.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // الأيقونة ومعاها النقطة الحمراء لو فيه إشعار
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(item.icon, size: 24.sp, color: color),
                            if (item.hasBadge)
                              Positioned(
                                top: -1.h,
                                right: -3.w,
                                child: Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: const BoxDecoration(
                                    color: AppColors.redColor2,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          item.labelKey.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyles.blackBold14.copyWith(
                            fontSize: 12.sp,
                            color: color,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  final String labelKey;
  final IconData icon;
  final bool hasBadge;

  const _BottomNavItemData({
    required this.labelKey,
    required this.icon,
    this.hasBadge = false,
  });
}
