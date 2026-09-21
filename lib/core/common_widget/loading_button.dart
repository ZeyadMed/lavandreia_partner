import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(
      color: color ?? AppColors.primaryColor,
      size: 50.sp,
    );
  }
}
