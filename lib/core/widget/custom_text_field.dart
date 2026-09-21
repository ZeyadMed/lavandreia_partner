import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class Customtextfield extends StatefulWidget {
  const Customtextfield({
    super.key,
    required this.hintText,
    required this.textEditingController,
    // final VoidCallback? onTap,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.readOnly = false,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.onSubmitted,
    this.decoration,
    this.maxLines,
    this.maxLength,
    this.borderRadious,
    this.style,
    this.minLines,
    this.labelText,
    this.hieght,
    this.onDateSelected,
    this.onTap,
    this.focusNode,
  });
  final String hintText;
  final TextEditingController textEditingController;

  /// بيتبعت من بره لما الشاشة عايزة تفتح الكيبورد على الخانة دي
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final double? borderRadious;
  final dynamic prefix;
  final dynamic suffix;
  final bool obscureText;
  final bool readOnly;
  final InputDecoration? decoration;
  final String? Function(String?)? onChanged;
  final Function(DateTime?)? onDateSelected;
  final VoidCallback? onTap;
  // ignore: prefer_typing_uninitialized_variables
  final TextInputType? keyboardType;
  final String? Function(String?)? onSubmitted;
  final String? Function(String?)? validator;
  final TextStyle? style;
  final String? labelText;
  final num? hieght;

  @override
  State<Customtextfield> createState() => _CustomtextfieldState();
}

class _CustomtextfieldState extends State<Customtextfield> {
  late bool hidden;

  @override
  void initState() {
    super.initState();
    hidden = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant Customtextfield oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent changed the obscureText prop, update internal hidden state
    if (oldWidget.obscureText != widget.obscureText) {
      hidden = widget.obscureText;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: AppColors.primaryColor),
          ),
          child: child!,
        );
      },
      lastDate: DateTime(2200),
    );

    if (pickedDate != null) {
      final day = pickedDate.day.toString().padLeft(2, '0');
      final month = pickedDate.month.toString().padLeft(2, '0');
      final year = pickedDate.year.toString();
      // Format as DD/MM/YYYY with leading zeros for day and month
      widget.textEditingController.text = '$day-$month-$year';
      if (widget.onDateSelected != null) {
        widget.onDateSelected!(pickedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.labelText != null
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 6),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LocalizedLabel(
                    text: widget.labelText ?? '',
                    style: widget.style ?? TextStyles.blackBold16,
                  ),
                ),
              )
            : const SizedBox.shrink(),
        SizedBox(height: 8.h),
        TextFormField(
          readOnly: widget.onDateSelected != null ? true : widget.readOnly,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines ?? 1,
          minLines: widget.minLines,
          onFieldSubmitted: widget.onSubmitted,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          controller: widget.textEditingController,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          obscureText: hidden,
          style: widget.style ?? TextStyles.darkRegular16,
          onTap:
              widget.onTap ??
              () {
                if (widget.onDateSelected != null) {
                  _selectDate(context);
                }
              },
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: (widget.hieght ?? 12.h).toDouble(),
              horizontal: 20.w,
            ),
            hintText: widget.hintText.tr(),
            fillColor: AppColors.secondaryColor,
            filled: true,
            // counterStyle: TextStyles.darkRegular16,
            hintStyle: TextStyles.greyColor2Regular14.copyWith(
              color: AppColors.greyColor2,
              fontSize: 14.sp,
            ),
            prefixIcon: widget.prefix,
            prefixIconColor: AppColors.greyColor2,
            suffixIcon: widget.suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.r),
              // borderSide: const BorderSide(
              // color: Colors.grey,
              // width: 0.5,
              // ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadious ?? 12.r),
              borderSide: const BorderSide(color: Colors.grey, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadious ?? 12.r),
              borderSide: const BorderSide(
                color: AppColors.primaryColor,
                width: 0.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadious ?? 12.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadious ?? 12.r),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
