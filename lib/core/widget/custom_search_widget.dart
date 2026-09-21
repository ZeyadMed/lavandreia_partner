import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;

import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class CustomSearchWidget extends StatefulWidget {
  final void Function(String)? onChanged;
  final void Function(String)? onSearchTap;
  final VoidCallback? onFilterTap;
  final String? hintText;
  final bool clearSearch;
  final TextEditingController? controller;

  const CustomSearchWidget({
    super.key,
    this.onChanged,
    this.onSearchTap,
    this.onFilterTap,
    this.hintText,
    this.controller,
    this.clearSearch = true,
  });

  @override
  State<CustomSearchWidget> createState() => _CustomSearchWidgetState();
}

class _CustomSearchWidgetState extends State<CustomSearchWidget> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  // bool clearSearch = true;

  @override
  void initState() {
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.primaryColor),
                onPressed: widget.onFilterTap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSearchTap,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.hintText?.tr() ?? "search",
                      hintStyle: TextStyles.darkRegular14,
                    ),
                    style: TextStyles.darkRegular16.copyWith(
                      decoration: TextDecoration.none,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.clearSearch == true
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.primaryColor,
                      ),
                      onPressed: () {
                        widget.controller?.clear();
                        widget.onChanged?.call('');
                      },
                    )
                  : SizedBox.shrink(),
            ],
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 1,
            color: _hasFocus ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
