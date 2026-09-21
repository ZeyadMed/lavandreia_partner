import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.collapsedLines = 2,
  });

  final String text;
  final TextStyle? style;
  final int collapsedLines;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _expanded ? null : widget.collapsedLines,
          overflow: TextOverflow.fade,
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(50, 24),
          ),
          child: LocalizedLabel(
            text: _expanded ? 'show less' : 'show more',
            style: TextStyles.darkBold14.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
