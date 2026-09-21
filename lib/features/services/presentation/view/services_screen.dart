import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/services/data/models/laundry_service.dart';
import 'package:lavanderia_partner/features/services/data/services_mock_data.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/add_service_sheet.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/edit_service_price_sheet.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  /// مؤقتاً من الداتا الوهمية لحد ما نربط الـ API
  final List<LaundryService> _services = ServicesMockData.all;

  /// نسخة من آخر حالة محفوظة، بنقارن بيها عشان نعرف
  /// إذا كان فيه تعديلات لسه متبعتتش للسيرفر
  late List<LaundryService> _savedSnapshot = _services
      .map((service) => service.copy())
      .toList();

  bool _isSaving = false;

  /// فيه تعديل لو العدد اتغير أو أي خدمة سعرها/حالتها اتغيرت
  bool get _hasChanges {
    if (_services.length != _savedSnapshot.length) return true;
    for (var i = 0; i < _services.length; i++) {
      if (!_services[i].isSameAs(_savedSnapshot[i])) return true;
    }
    return false;
  }

  int get _activeCount =>
      _services.where((service) => service.isActive).length;

  Future<void> _editPrice(LaundryService service) async {
    final price = await showEditServicePriceSheet(
      context: context,
      service: service,
    );
    if (price == null || !mounted) return;

    setState(() => service.price = price);
  }

  Future<void> _addService() async {
    final option = await showAddServiceSheet(
      context: context,
      existingIds: _services.map((service) => service.id).toSet(),
    );
    if (option == null || !mounted) return;

    // الخدمة الجديدة لازم يتحدّدلها سعر قبل ما تتضاف
    final added = LaundryService(
      id: option.id,
      labelKey: option.labelKey,
      emoji: option.emoji,
      price: '',
    );
    final price = await showEditServicePriceSheet(
      context: context,
      service: added,
    );
    if (price == null || !mounted) return;

    setState(() {
      added.price = price;
      _services.add(added);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    // مؤقتاً تأخير بسيط بدل نداء الـ API
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _savedSnapshot = _services.map((service) => service.copy()).toList();
    });
    _showMessage('services_saved', AppColors.greenColor);
  }

  void _showMessage(String messageKey, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LocalizedLabel(text: messageKey, style: TextStyles.whiteBold14),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      body: Column(
        children: [
          _ServicesHeader(activeCount: _activeCount),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              // آخر عنصر هو زرار الإضافة المنقّط
              itemCount: _services.length + 1,
              separatorBuilder: (_, _) => Gap(12.h),
              itemBuilder: (context, index) {
                if (index == _services.length) {
                  return _AddServiceButton(onTap: _addService);
                }

                final service = _services[index];
                return ServiceCard(
                  service: service,
                  onEdit: () => _editPrice(service),
                  onActiveChanged: (value) =>
                      setState(() => service.isActive = value),
                );
              },
            ),
          ),
          // شريط الحفظ بيظهر بس لما يكون فيه تعديلات
          if (_hasChanges)
            _SaveBar(isSaving: _isSaving, onSave: _save),
        ],
      ),
    );
  }
}

/// الهيدر الأزرق: عنوان الصفحة وتحته عدد الخدمات النشطة
class _ServicesHeader extends StatelessWidget {
  final int activeCount;

  const _ServicesHeader({required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        20.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedLabel(
            text: 'services',
            style: TextStyles.whiteText(22, weight: FontWeight.w800),
          ),
          Gap(4.h),
          Label(
            text: 'active_services_count'.tr(args: [activeCount.toString()]),
            style: TextStyles.whiteText(
              13,
              weight: FontWeight.w400,
            ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// الزرار المنقّط اللي تحت الليستة
class _AddServiceButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddServiceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DottedBorderBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18.sp, color: AppColors.primaryColor),
            Gap(8.w),
            LocalizedLabel(
              text: 'add_service',
              style: TextStyles.boldStyle(
                15,
                color: AppColors.primaryColor,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// إطار منقّط، مرسوم بـ CustomPainter عشان منضيفش باكدج جديد للمشروع
class DottedBorderBox extends StatelessWidget {
  final Widget child;

  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: 16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 14.w),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;

  const _DashedBorderPainter({required this.radius});

  static const double _dashWidth = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    // بنمشي على حدود المسار ونرسم شرطة وبعدها فراغ لحد ما نلف الإطار كله
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

/// شريط الحفظ اللي بيطلع من تحت لما يكون فيه تعديلات متحفظتش
class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveBar({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 14.h, 5.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: CustomButton(
          // بنقفل الضغط وقت الحفظ عشان مايتبعتش مرتين
          onPressed: isSaving ? () {} : onSave,
          title: isSaving ? 'saving' : 'save_changes',
          backgroundColor: isSaving
              ? AppColors.primaryColor.withValues(alpha: 0.6)
              : AppColors.primaryColor,
        ),
      ),
    );
  }
}
