import 'package:flutter/material.dart';

class CustomRadioButton<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final Color focusColor;
  final double strokeWidth;
  final Duration animationDuration;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const CustomRadioButton({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.size = 20.0,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.focusColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.child,
    this.padding,
    this.enabled = true,
  });

  bool get isSelected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => onChanged(value) : null,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: animationDuration,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: enabled
                      ? (isSelected ? activeColor : inactiveColor)
                      : inactiveColor.withOpacity(0.5),
                  width: strokeWidth,
                ),
                color: Colors.transparent,
              ),
              child: AnimatedScale(
                duration: animationDuration,
                scale: isSelected ? 1.0 : 0.0,
                child: Container(
                  margin: EdgeInsets.all(strokeWidth + 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: enabled ? activeColor : activeColor.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            if (child != null) ...[
              const SizedBox(width: 8),
              Opacity(
                opacity: enabled ? 1.0 : 0.5,
                child: child!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
