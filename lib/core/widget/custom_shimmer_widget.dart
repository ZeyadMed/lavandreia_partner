import 'package:flutter/material.dart';
import "package:shimmer/shimmer.dart";

class CustomShimmerWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? highlightColor;
  final BoxShape? shape;
  final double? borderRadius;

  const CustomShimmerWidget({
    super.key,
    this.height = 55,
    this.shape = BoxShape.rectangle,
    this.width = double.infinity,
    this.borderRadius,
    this.highlightColor = Colors.white,
  });

  const CustomShimmerWidget.circular({
    super.key,
    this.height = 20,
    this.width = 20,
    this.borderRadius,
    this.highlightColor = Colors.white,
  }) : shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: highlightColor!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: shape!,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius ?? 10),
        ),
      ),
    );
  }
}
