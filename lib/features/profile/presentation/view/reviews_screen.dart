import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/skeleton.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_review.dart';
import 'package:lavanderia_partner/features/profile/data/reviews_data_source.dart';
import 'package:lavanderia_partner/features/profile/presentation/view_model/reviews_cubit.dart';

/// صفحة تقييمات العملاء للمغسلة، بتجيب صفحة ورا صفحة مع السكرول
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewsCubit(getIt<ReviewsDataSource>())
        ..initPagination()
        ..fetch(page: 1),
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        appBar: const CustomAppBar(title: 'my_reviews'),
        body: BlocBuilder<ReviewsCubit, BaseState<LaundryReview>>(
          builder: (context, state) => _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BaseState<LaundryReview> state) {
    final cubit = context.read<ReviewsCubit>();

    // السحب للتحديث بيرجع لـ loading، فبنسيب اللستة القديمة ظاهرة لحد ما الجديدة توصل
    if (state.items.isEmpty) {
      if (state.isFailure) {
        return _CenteredMessage(
          text: 'reviews_load_failed',
          color: AppColors.redColor,
          onRetry: cubit.refresh,
        );
      }
      if (state.isSuccess) {
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: cubit.refresh,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: const _CenteredMessage(
                  text: 'no_reviews',
                  color: AppColors.greyColor3,
                  icon: Icons.star_outline_rounded,
                ),
              ),
            ),
          ),
        );
      }
      return const _ReviewsSkeleton();
    }

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.refresh,
      child: ListView.separated(
        controller: cubit.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, _) => Gap(10.h),
        itemBuilder: (context, index) {
          if (index < state.items.length) {
            return _ReviewCard(review: state.items[index]);
          }
          return _ListFooter(
            state: state,
            onRetry: () => cubit.fetch(page: state.page),
          );
        },
      ),
    );
  }
}

/// كارت تقييم واحد: اسم العميل والنجوم والتاريخ والتعليق
class _ReviewCard extends StatelessWidget {
  final LaundryReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final createdAt = review.createdAt;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.25),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.secondaryColor,
                child: Text(
                  review.customerName.isEmpty
                      ? '?'
                      : review.customerName.characters.first.toUpperCase(),
                  style: TextStyles.darkBold16.copyWith(
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Gap(10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.darkBold14,
                    ),
                    if (createdAt != null) ...[
                      Gap(2.h),
                      Text(
                        DateFormat(
                          'd MMM yyyy',
                          context.locale.toString(),
                        ).format(createdAt),
                        style: TextStyles.darkRegular12.copyWith(
                          color: AppColors.greyColor3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _RatingStars(rating: review.rating),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            Gap(10.h),
            Text(review.comment, style: TextStyles.darkRegular14),
          ],
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  final int rating;

  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18.sp,
            color: AppColors.lightOrangeColor,
          ),
      ],
    );
  }
}

/// آخر اللستة: لودينج الصفحة الجاية أو زرار إعادة المحاولة لو فشلت
class _ListFooter extends StatelessWidget {
  final BaseState<LaundryReview> state;
  final VoidCallback onRetry;

  const _ListFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }
    if (state.isLoadingMoreFauilare) {
      return Center(child: _RetryButton(onRetry: onRetry));
    }
    return const SizedBox.shrink();
  }
}

/// رسالة في نص الصفحة للفشل أو اللستة الفاضية
class _CenteredMessage extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback? onRetry;

  const _CenteredMessage({
    required this.text,
    required this.color,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 56.sp, color: AppColors.greyColor5),
            Gap(8.h),
          ],
          LocalizedLabel(
            text: text,
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(color: color),
          ),
          if (onRetry != null) _RetryButton(onRetry: onRetry!),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
      label: LocalizedLabel(
        text: 'try_again',
        style: TextStyles.darkBold14.copyWith(color: AppColors.primaryColor),
      ),
    );
  }
}

/// لودينج أول صفحة بنفس شكل [_ReviewCard]
class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: 6,
      separatorBuilder: (_, _) => Gap(10.h),
      itemBuilder: (_, _) => Container(
        padding: EdgeInsets.all(14.r),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 40.r, height: 40.r, radius: 20.r),
                  Gap(10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 100.w, height: 14.h),
                      Gap(6.h),
                      SkeletonBox(width: 70.w, height: 12.h),
                    ],
                  ),
                  const Spacer(),
                  SkeletonBox(width: 90.w, height: 16.h),
                ],
              ),
              Gap(12.h),
              SkeletonBox(height: 14.h),
              Gap(6.h),
              SkeletonBox(width: 180.w, height: 14.h),
            ],
          ),
        ),
      ),
    );
  }
}
