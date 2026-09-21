import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class ExpandableTextField extends StatefulWidget {
  final String collapsedText;
  final String expandedLabel;
  final String hintText;
  final void Function(String?)? onChanged;
  final TextEditingController? textEditingController;
  final Color backgroundColor;
  final Color borderColor;

  final Duration animationDuration;

  const ExpandableTextField({
    super.key,
    required this.collapsedText,
    required this.expandedLabel,
    required this.hintText,
    this.onChanged,
    this.textEditingController,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.borderColor = const Color(0xFFCCCCCC),
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<ExpandableTextField> createState() => _ExpandableTextFieldState();
}

class _ExpandableTextFieldState extends State<ExpandableTextField> {
  bool isExpanded = false;
  late final TextEditingController promoCodeController;
  late final bool _controllerProvided;

  @override
  void initState() {
    super.initState();
    _controllerProvided = widget.textEditingController != null;
    promoCodeController =
        widget.textEditingController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (!_controllerProvided) {
      promoCodeController.dispose();
    }
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: widget.animationDuration,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.borderColor),
        ),
        width: double.infinity,
        child: isExpanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LocalizedLabel(
                        text: widget.expandedLabel,
                        style: TextStyles.darkBold14,
                      ),
                      const Spacer(),
                      Icon(Icons.expand_less, color: Colors.grey),
                    ],
                  ),
                  const Gap(0),
                  Customtextfield(
                    hintText: widget.hintText,
                    textEditingController: promoCodeController,

                    style: TextStyles.darkRegular14,
                    // onChanged: widget.onChanged,
                  ),
                ],
              )
            : Row(
                children: [
                  LocalizedLabel(
                    text: widget.collapsedText,
                    style: TextStyles.darkBold14,
                  ),
                  const Spacer(),
                  Icon(Icons.expand_more, color: Colors.grey),
                ],
              ),
      ),
    );
  }
}
