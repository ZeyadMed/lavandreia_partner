import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// شاشة "بنبحث عن مندوبين قريبين" وهي الرحلة لسه محدش طلبها:
/// عربية ماشية جوه دايرة، وحواليها حلقة بتتملي كل دقيقة، وتحتها الوقت اللي فات
class DriverSearchIndicator extends StatefulWidget {
  /// الرحلة اللي بندور لها، الوقت بيتحسب من أول مرة ظهرت فيها
  final int tripId;

  const DriverSearchIndicator({super.key, required this.tripId});

  /// السيرفر مش بيبعت وقت إنشاء الرحلة، فبنحفظ أول مرة ظهر فيها البحث
  /// عشان العداد مايبدأش من الصفر مع كل تحديث للصفحة
  static final Map<int, DateTime> _startedAt = {};

  @override
  State<DriverSearchIndicator> createState() => _DriverSearchIndicatorState();
}

class _DriverSearchIndicatorState extends State<DriverSearchIndicator>
    with SingleTickerProviderStateMixin {
  // كل حاجة في الرسمة بتلف عدد صحيح من المرات في الدورة دي عشان تتكرر من غير قطع
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final DateTime _startedAt = DriverSearchIndicator._startedAt.putIfAbsent(
    widget.tripId,
    DateTime.now,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 170.w;
    return Column(
      children: [
        LocalizedLabel(
          text: 'searching_nearby_drivers',
          textAlign: TextAlign.center,
          style: TextStyles.boldStyle(17, weight: FontWeight.w800),
        ),
        Gap(18.h),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final elapsed = DateTime.now().difference(_startedAt);
            final minuteProgress = (elapsed.inMilliseconds % 60000) / 60000;
            return Column(
              children: [
                SizedBox.square(
                  dimension: size,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(progress: minuteProgress),
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.045),
                      child: CustomPaint(
                        painter: _CarScenePainter(t: _controller.value),
                      ),
                    ),
                  ),
                ),
                Gap(14.h),
                // الأرقام دايمًا من الشمال لليمين حتى في العربي
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _format(elapsed),
                    style: TextStyles.boldStyle(30, weight: FontWeight.w800)
                        .copyWith(
                          height: 1.1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
              ],
            );
          },
        ),
        Gap(6.h),
        LocalizedLabel(
          text: 'searching_nearby_drivers_hint',
          textAlign: TextAlign.center,
          style: TextStyles.darkRegular12.copyWith(color: AppColors.greyColor3),
        ),
      ],
    );
  }

  /// 00:24، ولو عدّى ساعة 1:02:05
  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return d.inHours > 0
        ? '${d.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

/// الحلقة الرمادي وفوقها الجزء الأزرق اللي بيتملي مع ثواني الدقيقة
class _ProgressRingPainter extends CustomPainter {
  final double progress;

  _ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.035;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.width - stroke) / 2,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0xffE6E9EF),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primaryColor,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

/// عربية بشنط على السقف ماشية قدام جبال، الجبال والطريق بيتحركوا
/// والعجل بيلف. [t] من 0 لـ 1 ومع كل لفة الرسمة بترجع لنفس شكلها
class _CarScenePainter extends CustomPainter {
  final double t;

  _CarScenePainter({required this.t});

  static const _sky = Color(0xffDCE7FB);
  static const _farMountain = Color(0xffBACEF4);
  static const _nearMountain = Color(0xff92B1EE);
  static const _ground = Color(0xffEDF3FD);
  static const _road = Color(0xffC9D8F6);
  static const _carBody = AppColors.primaryColor;
  static const _carDark = Color(0xff2453B0);
  static const _window = Color(0xffE4EEFF);
  static const _tyre = Color(0xff1F2533);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.clipPath(Path()..addOval(Offset.zero & size));

    canvas.drawRect(Offset.zero & size, Paint()..color = _sky);

    // العربية رايحة شمال، فالمنظر بيتحرك يمين
    _mountains(
      canvas,
      size,
      offset: t * w,
      baseY: 0.66 * h,
      peaks: const [(0.05, 0.22), (0.38, 0.16), (0.70, 0.26)],
      halfWidth: 0.27 * w,
      color: _farMountain,
    );
    _mountains(
      canvas,
      size,
      offset: (t * 2 % 1) * w,
      baseY: 0.66 * h,
      peaks: const [(0.20, 0.34), (0.55, 0.30), (0.88, 0.38)],
      halfWidth: 0.22 * w,
      color: _nearMountain,
    );

    // الأرض وخطوط الطريق
    canvas.drawRect(Rect.fromLTRB(0, 0.66 * h, w, h), Paint()..color = _ground);
    final dash = Paint()
      ..color = _road
      ..strokeWidth = 0.022 * h
      ..strokeCap = StrokeCap.round;
    final dashPeriod = w / 4;
    final dashShift = (t * 8 % 1) * dashPeriod;
    for (var x = -dashPeriod + dashShift; x < w; x += dashPeriod) {
      canvas.drawLine(
        Offset(x, 0.86 * h),
        Offset(x + dashPeriod * 0.45, 0.86 * h),
        dash,
      );
    }

    _car(canvas, size);
    canvas.restore();
  }

  void _mountains(
    Canvas canvas,
    Size size, {
    required double offset,
    required double baseY,
    required List<(double, double)> peaks,
    required double halfWidth,
    required Color color,
  }) {
    final fill = Paint()..color = color;
    final snow = Paint()..color = Colors.white.withValues(alpha: 0.95);
    // مرسومة مرتين ورا بعض عشان لما تتزحزح متبقاش فيه فجوة
    for (final shift in [offset - size.width, offset]) {
      for (final (px, py) in peaks) {
        final x = px * size.width + shift;
        final y = py * size.height;
        canvas.drawPath(
          Path()
            ..moveTo(x - halfWidth, baseY)
            ..lineTo(x, y)
            ..lineTo(x + halfWidth, baseY)
            ..close(),
          fill,
        );
        // قمة التلج: نفس ميل الجبل لحد ربع ارتفاعه تقريبًا
        final capDepth = (baseY - y) * 0.22;
        final capHalf = halfWidth * capDepth / (baseY - y);
        canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x + capHalf, y + capDepth)
            ..lineTo(x + capHalf * 0.35, y + capDepth * 0.75)
            ..lineTo(x, y + capDepth)
            ..lineTo(x - capHalf * 0.4, y + capDepth * 0.7)
            ..lineTo(x - capHalf, y + capDepth)
            ..close(),
          snow,
        );
      }
    }
  }

  void _car(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // نطّة خفيفة كأنها ماشية على طريق
    final bounce = math.sin(t * math.pi * 2 * 12) * 0.006 * h;
    final groundY = 0.80 * h;
    final wheelR = 0.075 * w;
    final wheelY = groundY - wheelR;

    // ضل تحت العربية
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.5 * w, groundY + 0.008 * h),
        width: 0.66 * w,
        height: 0.04 * h,
      ),
      Paint()..color = const Color(0x22000000),
    );

    canvas.save();
    canvas.translate(0, bounce);

    // الكابينة، الزجاج الأمامي مايل ناحية الشمال (قدام العربية)
    final cabinTop = 0.42 * h;
    final cabinBottom = 0.56 * h;
    final cabin = Path()
      ..moveTo(0.27 * w, cabinBottom)
      ..quadraticBezierTo(0.33 * w, cabinTop, 0.40 * w, cabinTop)
      ..lineTo(0.64 * w, cabinTop)
      ..quadraticBezierTo(0.70 * w, cabinTop + 0.01 * h, 0.72 * w, cabinBottom)
      ..close();
    canvas.drawPath(cabin, Paint()..color = _carBody);

    // الشبابيك
    final windowPaint = Paint()..color = _window;
    final winTop = cabinTop + 0.025 * h;
    final winBottom = cabinBottom - 0.005 * h;
    canvas.drawPath(
      Path()
        ..moveTo(0.315 * w, winBottom)
        ..quadraticBezierTo(0.35 * w, winTop, 0.41 * w, winTop)
        ..lineTo(0.49 * w, winTop)
        ..lineTo(0.49 * w, winBottom)
        ..close(),
      windowPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0.515 * w, winTop)
        ..lineTo(0.63 * w, winTop)
        ..quadraticBezierTo(0.675 * w, winTop + 0.01 * h, 0.685 * w, winBottom)
        ..lineTo(0.515 * w, winBottom)
        ..close(),
      windowPaint,
    );

    // السواق: راس وكتف ورا الشباك الأمامي
    canvas.drawCircle(
      Offset(0.44 * w, winTop + 0.04 * h),
      0.024 * w,
      Paint()..color = const Color(0xffF2C9A5),
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(0.44 * w, winTop + 0.035 * h),
        radius: 0.026 * w,
      ),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xff5B3A29),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0.415 * w, winTop + 0.064 * h, 0.47 * w, winBottom),
        Radius.circular(0.02 * w),
      ),
      Paint()..color = const Color(0xffF06A6A),
    );

    // الشنط والرف اللي على السقف
    final rack = Paint()
      ..color = _carDark
      ..strokeWidth = 0.012 * h
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0.40 * w, cabinTop - 0.012 * h),
      Offset(0.64 * w, cabinTop - 0.012 * h),
      rack,
    );
    canvas.drawLine(
      Offset(0.43 * w, cabinTop - 0.012 * h),
      Offset(0.43 * w, cabinTop),
      rack,
    );
    canvas.drawLine(
      Offset(0.61 * w, cabinTop - 0.012 * h),
      Offset(0.61 * w, cabinTop),
      rack,
    );
    _suitcase(
      canvas,
      Rect.fromLTRB(
        0.42 * w,
        cabinTop - 0.075 * h,
        0.52 * w,
        cabinTop - 0.02 * h,
      ),
      const Color(0xffF5F8FF),
    );
    _suitcase(
      canvas,
      Rect.fromLTRB(
        0.525 * w,
        cabinTop - 0.09 * h,
        0.62 * w,
        cabinTop - 0.02 * h,
      ),
      const Color(0xffD5E1F8),
    );

    // جسم العربية
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(0.16 * w, cabinBottom, 0.84 * w, wheelY + 0.02 * h),
      topLeft: Radius.circular(0.06 * w),
      topRight: Radius.circular(0.04 * w),
      bottomLeft: Radius.circular(0.03 * w),
      bottomRight: Radius.circular(0.03 * w),
    );
    canvas.drawRRect(body, Paint()..color = _carBody);
    // خط جانبي ومقبض الباب
    canvas.drawLine(
      Offset(0.20 * w, cabinBottom + 0.05 * h),
      Offset(0.80 * w, cabinBottom + 0.05 * h),
      Paint()
        ..color = _carDark
        ..strokeWidth = 0.008 * h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.53 * w, cabinBottom + 0.018 * h, 0.04 * w, 0.012 * h),
        Radius.circular(0.01 * w),
      ),
      Paint()..color = _carDark,
    );
    // الفانوس الأمامي والخلفي
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.155 * w, cabinBottom + 0.02 * h, 0.03 * w, 0.025 * h),
        Radius.circular(0.01 * w),
      ),
      Paint()..color = const Color(0xffFFE08A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.82 * w, cabinBottom + 0.02 * h, 0.025 * w, 0.03 * h),
        Radius.circular(0.01 * w),
      ),
      Paint()..color = const Color(0xffFF6B6B),
    );
    canvas.restore();

    // العجل مش بينط مع الجسم
    _wheel(canvas, Offset(0.31 * w, wheelY), wheelR);
    _wheel(canvas, Offset(0.69 * w, wheelY), wheelR);
  }

  void _suitcase(Canvas canvas, Rect rect, Color color) {
    final r = Radius.circular(rect.height * 0.18);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, r), Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, r),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.height * 0.08
        ..color = _carDark.withValues(alpha: 0.35),
    );
    canvas.drawLine(
      Offset(rect.center.dx, rect.top + rect.height * 0.2),
      Offset(rect.center.dx, rect.bottom - rect.height * 0.2),
      Paint()
        ..strokeWidth = rect.height * 0.08
        ..color = _carDark.withValues(alpha: 0.35),
    );
  }

  void _wheel(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = _tyre);
    canvas.drawCircle(center, r * 0.55, Paint()..color = Colors.white);
    // العربية رايحة شمال فالعجل بيلف عكس عقارب الساعة
    final angle = -t * math.pi * 2 * 6;
    final spoke = Paint()
      ..color = const Color(0xff9AA6BD)
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = angle + i * math.pi / 2;
      canvas.drawLine(
        center,
        center + Offset(math.cos(a), math.sin(a)) * r * 0.45,
        spoke,
      );
    }
    canvas.drawCircle(center, r * 0.14, Paint()..color = _tyre);
  }

  @override
  bool shouldRepaint(_CarScenePainter old) => old.t != t;
}
