import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/widget/skeleton.dart';

/// لودينج صفحة الخدمات بنفس شكل الجروبات و [ServiceCard]
class ServicesSkeleton extends StatelessWidget {
  /// عدد الأصناف في كل جروب، مختلف عشان الشكل مايبانش متكرر
  static const _groupSizes = [3, 2, 3];

  const ServicesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      children: [
        for (final size in _groupSizes)
          Padding(
            padding: EdgeInsets.only(bottom: 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الخدمة وعدد أصنافها
                SkeletonShimmer(child: SkeletonBox(width: 130.w, height: 18.h)),
                Gap(10.h),
                for (var i = 0; i < size; i++) ...[
                  const _ServiceCardSkeleton(),
                  Gap(10.h),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// نفس أبعاد [ServiceCard]: صورة 44 واسم وسعر وأيقونة تعديل
class _ServiceCardSkeleton extends StatelessWidget {
  const _ServiceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SkeletonShimmer(
        child: Row(
          children: [
            SkeletonBox(width: 44.w, height: 44.w, radius: 12.r),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140.w, height: 15.h),
                  Gap(6.h),
                  SkeletonBox(width: 80.w, height: 12.h),
                ],
              ),
            ),
            Gap(8.w),
            SkeletonBox(width: 20.w, height: 20.w, radius: 5.r),
          ],
        ),
      ),
    );
  }
}

/// لودينج لستة الخدمات في صفحة الإعداد بنفس شكل كارت الخدمة المقفول
class SetupServicesSkeleton extends StatelessWidget {
  const SetupServicesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 30.h),
      children: [
        // مكان جملة "اختار خدماتك"
        Center(
          child: SkeletonShimmer(
            child: SkeletonBox(width: 220.w, height: 16.h),
          ),
        ),
        Gap(16.h),
        for (var i = 0; i < 6; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: SkeletonShimmer(
                child: Row(
                  children: [
                    SkeletonBox(width: 24.w, height: 24.w, radius: 6.r),
                    Gap(10.w),
                    SkeletonBox(width: 120.w, height: 16.h),
                    const Spacer(),
                    SkeletonBox(width: 18.w, height: 18.w, radius: 4.r),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// لودينج أصناف الخدمة جوه الكارت المفتوح: اسم الصنف وحقل السعر
class ServiceItemsSkeleton extends StatelessWidget {
  const ServiceItemsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  SkeletonBox(width: 110.w, height: 14.h),
                  const Spacer(),
                  SkeletonBox(width: 120.w, height: 44.h, radius: 10.r),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
