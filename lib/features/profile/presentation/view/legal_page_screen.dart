import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/profile/data/legal_content.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/legal_widgets.dart';

/// صفحة نصية بأقسام ثابتة، بتستخدمها الشروط والأحكام
/// سياسة الخصوصية جاية من الـ API في PrivacyPolicyScreen بنفس الشكل
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
            LastUpdatedBanner(text: lastUpdatedKey.tr()),
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

/// قسم واحد: عنوان وتحته النص
class _SectionCard extends StatelessWidget {
  final LegalSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return LegalCard(
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
