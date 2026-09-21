import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class CustomDropDown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) getLabel;
  final void Function(T?) onChanged;
  final String hint;

  const CustomDropDown({
    super.key,
    required this.value,
    required this.items,
    required this.getLabel,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // مهم للعربي
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            hint: Text(
              hint,
              style: TextStyles.blackBold16.copyWith(color: Colors.grey),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey,
            ),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(getLabel(item), style: TextStyles.blackBold16),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
