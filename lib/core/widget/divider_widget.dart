import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// A horizontal divider with a centered text (default: Arabic "او").
///
/// Example:
/// DividerWidget()
/// DividerWidget(text: 'OR', lineColor: Colors.grey)
class DividerWidget extends StatelessWidget {
  final String text;
  final Color lineColor;
  final double thickness;
  final double spacing;
  final TextStyle? textStyle;

  const DividerWidget({
    super.key,
    required this.text,
    this.lineColor = const Color(0xFF989eb3),
    this.thickness = 0.5,
    this.spacing = 12.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ??
        TextStyles.blackBold16.copyWith(
          color: lineColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        );

    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: spacing),
              height: thickness,
              color: lineColor,
            ),
          ),
          LocalizedLabel(
            text: text,
            style: effectiveTextStyle,
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: spacing),
              height: thickness,
              color: lineColor,
            ),
          ),
        ],
      ),
    );
  }
}
