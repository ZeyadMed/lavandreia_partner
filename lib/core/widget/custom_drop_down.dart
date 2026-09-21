import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:lavanderia_partner/core/theme/text_styles.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(
            tr(hint),
            style: TextStyles.darkBold16.copyWith(color: Colors.grey),
            textDirection: ui.TextDirection.rtl,
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: items,
          onChanged: onChanged,
          style: TextStyles.darkBold16,
          dropdownColor: Colors.white,
        ),
      ),
    );
  }
}
