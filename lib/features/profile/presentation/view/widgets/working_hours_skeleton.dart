import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/widget/skeleton.dart';

/// لودينج صفحة مواعيد العمل بنفس شكل [WorkingDayCard]
/// سبع أيام، والأخير (الجمعة) مقفول من غير خانات الوقت زي الافتراضي
class WorkingHoursSkeleton extends StatelessWidget {
  const WorkingHoursSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      children: [
        // مكان جملة "حدد مواعيد عمل مغسلتك"
        Center(
          child: SkeletonShimmer(
            child: SkeletonBox(width: 220.w, height: 16.h),
          ),
        ),
        Gap(16.h),
        for (var i = 0; i < 7; i++) _DayCardSkeleton(showTimes: i < 6),
      ],
    );
  }
}

class _DayCardSkeleton extends StatelessWidget {
  final bool showTimes;

  const _DayCardSkeleton({required this.showTimes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.25),
            width: 0.9,
          ),
        ),
        child: SkeletonShimmer(
          child: Column(
            children: [
              // اسم اليوم وكلمة "مغلق" والسويتش
              Row(
                children: [
                  SkeletonBox(width: 80.w, height: 16.h),
                  const Spacer(),
                  SkeletonBox(width: 36.w, height: 14.h),
                  Gap(10.w),
                  SkeletonBox(width: 48.w, height: 26.h, radius: 13.r),
                ],
              ),
              // خانتين "من" و "إلى"
              if (showTimes) ...[
                Gap(12.h),
                Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 50.h, radius: 10.r)),
                    Gap(10.w),
                    Expanded(child: SkeletonBox(height: 50.h, radius: 10.r)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
