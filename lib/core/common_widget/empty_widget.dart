import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/flexiable_image.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    required this.text,
    required this.image,
    this.height,
    this.weight,
  });

  final String text;
  final String image;
  final double? height;
  final double? weight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20.h,
      children: [
        FlexibleImage(
          source: image,
          height: height ?? 150.h,
          width: weight ?? 150.w,
        ),
        LocalizedLabel(
          text: text,
          style: TextStyles.darkRegular16.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
