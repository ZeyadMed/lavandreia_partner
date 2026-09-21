import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class CustomButton extends StatelessWidget {
  final String title;
  final Widget? icon;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width; // ← Now properly used
  final double? height;
  final VoidCallback onPressed;
  final bool isIcon;
  final double? fontSize;
  final FontWeight? fontWeight;

  const CustomButton({
    super.key,
    this.title = "",
    this.icon,
    this.backgroundColor = AppColors.primaryColor,
    this.textColor = Colors.white,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(15),
    required this.onPressed,
    this.iconBackgroundColor = AppColors.whiteColor,
    this.isIcon = false,
    this.fontSize,
    this.borderColor,
    this.fontWeight,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width ?? double.infinity, // ← Fixed
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
          ),
          child: isIcon
              ? Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[icon!, Gap(10.w)],
                      LocalizedLabel(
                        text: title,
                        style: TextStyles.darkBold16.copyWith(
                          color: textColor,
                          fontWeight: fontWeight ?? FontWeight.w700,
                          fontSize: fontSize ?? 16.spMax,
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: LocalizedLabel(
                    text: title,
                    style: TextStyles.darkBold16.copyWith(
                      color: textColor,
                      fontWeight: fontWeight ?? FontWeight.w700,
                      fontSize: fontSize ?? 16.spMax,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
