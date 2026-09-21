import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/profile/data/legal_content.dart';

/// صفحة نصية بأقسام، بتستخدمها الشروط والأحكام وسياسة الخصوصية
/// الاتنين نفس الشكل بالظبط والفرق في المحتوى بس
class LegalPageScreen extends StatelessWidget {
  final String titleKey;
  final List<LegalSection> sections;

  /// تاريخ آخر تحديث، بيتعرض فوق كإشارة إن النص متجدد
  final String lastUpdatedKey;

  const LegalPageScreen({
    super.key,
    required this.titleKey,
    required this.sections,
    required this.lastUpdatedKey,
  });

  /// صفحة الشروط والأحكام
  const LegalPageScreen.terms({super.key})
    : titleKey = 'terms_and_conditions',
      sections = LegalContent.terms,
      lastUpdatedKey = 'terms_last_updated';

  /// صفحة سياسة الخصوصية
  const LegalPageScreen.privacy({super.key})
    : titleKey = 'privacy_policy',
      sections = LegalContent.privacy,
      lastUpdatedKey = 'privacy_last_updated';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      appBar: CustomAppBar(title: titleKey),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LastUpdatedBanner(labelKey: lastUpdatedKey),
            Gap(14.h),
            ...sections.map(
              (section) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _SectionCard(section: section),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريط صغير فوق فيه تاريخ آخر تحديث للنص
class _LastUpdatedBanner extends StatelessWidget {
  final String labelKey;

  const _LastUpdatedBanner({required this.labelKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18.sp,
            color: AppColors.primaryColor,
          ),
          Gap(10.w),
          Expanded(
            child: LocalizedLabel(
              text: labelKey,
              maxLines: 2,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم واحد: عنوان وتحته النص
class _SectionCard extends StatelessWidget {
  final LegalSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedLabel(
            text: section.titleKey,
            maxLines: 2,
            style: TextStyles.boldStyle(15, weight: FontWeight.w700),
          ),
          Gap(8.h),
          LocalizedLabel(
            text: section.bodyKey,
            // النص الطويل لازم يلف بدل ما يتقص
            maxLines: null,
            overflow: TextOverflow.visible,
            style: TextStyles.darkRegular14.copyWith(
              color: AppColors.greyColor3,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
