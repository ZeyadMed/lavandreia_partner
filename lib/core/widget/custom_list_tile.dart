import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class CustomListTile extends StatelessWidget {
  final String text;
  final double? height;
  final double? borderRadious;
  final Color? iconColor;
  final Color? textColor;
  final Color? contianerColor;
  final void Function()? onTap;
  final IconData? icon;

  const CustomListTile({
    super.key,
    required this.text,
    this.iconColor,
    required this.onTap,
    this.contianerColor,
    this.textColor,
    this.height,
    this.borderRadious,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 50.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: contianerColor ?? Colors.white,
          // borderRadius: BorderRadius.circular(borderRadious ?? 12.r),
          // only bottom border (single line at bottom)
          border: Border(
            bottom: BorderSide(color: AppColors.greyColor, width: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                icon ?? Icons.person,
                size: 20.sp,
                color: iconColor ?? AppColors.greyColor,
              ),
              Gap(20),
              LocalizedLabel(
                text: text,
                style: TextStyles.darkBold16.copyWith(
                  color: textColor ?? AppColors.blackColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 15.sp,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
