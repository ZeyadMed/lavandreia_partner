import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// اللمعة اللي بتتحط على محتوى الكارت بس، مش على الكارت نفسه
/// عشان الكارت يفضل أبيض بنفس شكل العرض الفعلي والبلوكات اللي جواه هي اللي بتلمع
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}

/// بلوك رمادي مكان نص أو صورة، لازم يكون جوه [SkeletonShimmer]
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double? radius;

  const SkeletonBox({super.key, this.width, required this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius ?? 6.r),
      ),
    );
  }
}
