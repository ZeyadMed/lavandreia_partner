import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class ContactWidget extends StatelessWidget {
  const ContactWidget({
    super.key,
    this.onTap,
    required this.svgImage,
    required this.title,
  });

  final void Function()? onTap;
  final String svgImage;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xffe8ecf5),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                svgImage,
                // ignore: deprecated_member_use
                color: AppColors.primaryColor,
                height: 26.h,
                width: 26.w,
              ),
              Gap(15.w),
              LocalizedLabel(text: title, style: TextStyles.darkBold14),
            ],
          ),
        ),
      ),
    );
  }
}
