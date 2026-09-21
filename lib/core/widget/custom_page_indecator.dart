import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';

class CustomPageIndicator extends StatelessWidget {
  final int currentIndex;
  final int itemCount;
  final double dotSize;
  final double activeDotWidth;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;

  const CustomPageIndicator({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    this.dotSize = 8,
    this.activeDotWidth = 32,
    this.spacing = 12,
    this.activeColor = AppColors.primaryColor,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(itemCount, (index) {
            final isActive = index == currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? activeDotWidth : dotSize,
              height: dotSize,
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(dotSize),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 2;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
