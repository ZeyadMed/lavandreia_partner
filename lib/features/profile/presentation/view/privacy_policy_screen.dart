import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/skeleton.dart';
import 'package:lavanderia_partner/features/profile/data/app_info_data_source.dart';
import 'package:lavanderia_partner/features/profile/data/models/privacy_policy.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/legal_widgets.dart';
import 'package:lavanderia_partner/features/profile/presentation/view_model/app_info_cubits.dart';
import 'package:url_launcher/url_launcher.dart';

/// سياسة الخصوصية: المحتوى HTML بيتكتب من لوحة التحكم
/// بنفس شكل صفحة الشروط، شريط آخر تحديث وتحته المحتوى في كارت
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PrivacyPolicyCubit(getIt<AppInfoDataSource>())..fetch(),
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        appBar: const CustomAppBar(title: 'privacy_policy'),
        body: BlocBuilder<PrivacyPolicyCubit, BaseState<PrivacyPolicy>>(
          builder: (context, state) {
            final cubit = context.read<PrivacyPolicyCubit>();
            final policy = state.data;
            if (policy == null) {
              return state.isFailure
                  ? _RetryMessage(onRetry: cubit.fetch)
                  : const _PrivacyPolicySkeleton();
            }
            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: cubit.fetch,
              child: _PrivacyPolicyContent(policy: policy),
            );
          },
        ),
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  final PrivacyPolicy policy;

  const _PrivacyPolicyContent({required this.policy});

  /// اللينكات اللي جوه المحتوى بتفتح في المتصفح
  /// المحتوى متكتب من لوحة التحكم، فاللينك الغلط بيتجاهل بدل ما يكراش
  Future<bool> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedAt = policy.updatedAt;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      children: [
        if (updatedAt != null) ...[
          LastUpdatedBanner(
            text: 'last_updated_on'.tr(
              args: [
                DateFormat(
                  'd MMMM yyyy',
                  context.locale.toString(),
                ).format(updatedAt),
              ],
            ),
          ),
          Gap(14.h),
        ],
        LegalCard(
          child: HtmlWidget(
            policy.content,
            textStyle: TextStyles.darkRegular14.copyWith(
              color: AppColors.greyColor3,
              height: 1.6,
            ),
            onTapUrl: _openLink,
          ),
        ),
      ],
    );
  }
}

/// لودينج بنفس شكل الصفحة: شريط التاريخ وتحته كارت فيه سطور
class _PrivacyPolicySkeleton extends StatelessWidget {
  const _PrivacyPolicySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
      children: [
        SkeletonShimmer(child: SkeletonBox(height: 42.h, radius: 12.r)),
        Gap(14.h),
        LegalCard(
          child: SkeletonShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160.w, height: 18.h),
                Gap(14.h),
                for (var i = 0; i < 8; i++) ...[
                  // آخر سطر في كل فقرة أقصر زي النص الحقيقي
                  SkeletonBox(width: i % 4 == 3 ? 180.w : null, height: 12.h),
                  Gap(10.h),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RetryMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalizedLabel(
            text: 'privacy_policy_load_failed',
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(color: AppColors.redColor),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
            label: LocalizedLabel(
              text: 'try_again',
              style: TextStyles.darkBold14.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
