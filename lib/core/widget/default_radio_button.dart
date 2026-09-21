import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class DefaultRadioButton extends StatefulWidget {
  final Color? borderColor;
  final Color? fillColor;
  final double? fillRadios;
  final String title;
  final TextStyle? titleStyle;
  final String iconPath;
  final Color? iconColor;
  final Color? containerBorderColor;
  final Color? backgroundColor;
  final Widget? titleWidget;
  final void Function()? onTap;
  final void Function()? iconOnTap;
  final bool selected;
  final bool moveToEnd;
  final bool moveIconToStart;
  final bool withMargin;
  final bool isExpanded;
  const DefaultRadioButton({
    super.key,
    this.borderColor,
    this.fillColor,
    this.fillRadios,
    this.title = '',
    this.titleStyle,
    this.iconPath = '',
    this.titleWidget,
    this.iconColor,
    this.onTap,
    required this.selected,
    this.iconOnTap,
    this.containerBorderColor,
    this.moveToEnd = false,
    this.withMargin = false,
    this.moveIconToStart = false,
    this.isExpanded = true,
    this.backgroundColor,
  });

  @override
  State<DefaultRadioButton> createState() => _DefaultRadioButtonState();
}

class _DefaultRadioButtonState extends State<DefaultRadioButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      onTap: widget.onTap,
      child: Container(
        margin: widget.withMargin
            ? EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w)
            : null,
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: widget.containerBorderColor != null
              ? Border.all(color: widget.containerBorderColor!)
              : null,
          borderRadius: BorderRadius.circular(10.sp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.moveToEnd)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.borderColor ?? AppColors.primaryColor,
                  ),
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 500),
                  crossFadeState: widget.selected
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Container(
                    height: widget.fillRadios ?? 15.h,
                    width: widget.fillRadios ?? 15.w,
                    decoration: BoxDecoration(
                      color: widget.fillColor ?? AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  secondChild: Container(
                    height: widget.fillRadios ?? 15.h,
                    width: widget.fillRadios ?? 15.w,
                    color: Colors.transparent,
                  ),
                ),
              ),
            if (!widget.moveToEnd) SizedBox(width: 10.w),
            if (widget.iconPath.isNotEmpty && widget.moveIconToStart)
              InkWell(
                onTap: widget.iconOnTap,
                child: SvgPicture.asset(
                  widget.iconPath,
                  width: 30.w,
                  height: 30.h,
                  color: widget.iconColor,
                ),
              ),
            if (widget.iconPath.isNotEmpty && widget.moveIconToStart)
              SizedBox(width: 10.w),
            if (widget.title.isNotEmpty)
              widget.isExpanded
                  ? Expanded(
                      child: LocalizedLabel(
                        text: widget.title,
                        style: TextStyles.blackBold16,
                      ),
                    )
                  : Flexible(
                      child: LocalizedLabel(
                        text: widget.title,
                        style: TextStyles.blackBold16,
                      ),
                    ),
            if (widget.titleWidget != null) widget.titleWidget!,
            if (widget.iconPath.isNotEmpty && !widget.moveIconToStart)
              InkWell(
                onTap: widget.iconOnTap,
                child: SvgPicture.asset(
                  widget.iconPath,
                  width: 30.w,
                  height: 30.h,
                  color: widget.iconColor,
                ),
              ),
            if (widget.moveToEnd) SizedBox(width: 10.w),
            if (widget.moveToEnd)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.borderColor ?? AppColors.primaryColor,
                  ),
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 500),
                  crossFadeState: widget.selected
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Container(
                    height: widget.fillRadios ?? 15.h,
                    width: widget.fillRadios ?? 15.w,
                    decoration: BoxDecoration(
                      color: widget.fillColor ?? AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  secondChild: Container(
                    height: widget.fillRadios ?? 15.h,
                    width: widget.fillRadios ?? 15.w,
                    color: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BorderRadioButton extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final Widget? titleWidget;
  final bool selected;
  final bool isExpanded;
  final VoidCallback? onTap;

  const BorderRadioButton({
    super.key,
    required this.title,
    required this.titleStyle,
    this.titleWidget,
    this.isExpanded = false,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyColor, width: 0.5),
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DefaultRadioButton(
          title: title,
          titleStyle: titleStyle,
          titleWidget: titleWidget,
          selected: selected,
          isExpanded: isExpanded,
          onTap: onTap,
        ),
      ),
    );
  }
}
