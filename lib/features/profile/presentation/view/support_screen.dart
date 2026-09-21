import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/helpers/social_media_functions.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/profile/data/legal_content.dart';

/// الدعم والمساعدة: وسائل التواصل وتحتها الأسئلة الشائعة
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final social = SocialMediaUtils();

    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      appBar: const CustomAppBar(title: 'support_and_help'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SupportIntro(),
            Gap(16.h),

            _SectionTitle(labelKey: 'contact_us'),
            Gap(10.h),
            _ContactTile(
              icon: Icons.phone_outlined,
              labelKey: 'contact_by_phone',
              value: SupportContacts.phone,
              color: AppColors.primaryColor,
              onTap: () =>
                  social.launchPhoneNumber(SupportContacts.phone, context),
            ),
            Gap(10.h),
            _ContactTile(
              icon: Icons.chat_bubble_outline,
              labelKey: 'contact_by_whatsapp',
              value: SupportContacts.whatsapp,
              color: AppColors.greenColor,
              onTap: () =>
                  social.launchWhatsApp(SupportContacts.whatsapp, context),
            ),
            Gap(10.h),
            _ContactTile(
              icon: Icons.mail_outline,
              labelKey: 'contact_by_email',
              value: SupportContacts.email,
              color: AppColors.orangeColor,
              onTap: () => social.launchEmail(SupportContacts.email, context),
            ),
            Gap(22.h),

            _SectionTitle(labelKey: 'faq'),
            Gap(10.h),
            ...LegalContent.faq.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _FaqTile(section: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كارت ترحيبي فوق الصفحة
class _SupportIntro extends StatelessWidget {
  const _SupportIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 38.sp,
            color: AppColors.whiteColor,
          ),
          Gap(10.h),
          LocalizedLabel(
            text: 'support_intro_title',
            textAlign: TextAlign.center,
            style: TextStyles.whiteText(17, weight: FontWeight.w800),
          ),
          Gap(6.h),
          LocalizedLabel(
            text: 'support_intro_body',
            textAlign: TextAlign.center,
            maxLines: 3,
            style: TextStyles.whiteText(
              13,
              weight: FontWeight.w400,
            ).copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String labelKey;

  const _SectionTitle({required this.labelKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: LocalizedLabel(
          text: labelKey,
          style: TextStyles.boldStyle(16, weight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// وسيلة تواصل واحدة: أيقونة ملونة والعنوان فوق القيمة
class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.labelKey,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 20.sp, color: color),
            ),
            Gap(14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedLabel(
                    text: labelKey,
                    style: TextStyles.boldStyle(14, weight: FontWeight.w600),
                  ),
                  Gap(3.h),
                  // الأرقام والإيميل دايماً من الشمال لليمين
                  // حتى والواجهة عربي، عشان الـ + مايتنقلش لآخر الرقم
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Label(
                        text: value,
                        maxLines: 1,
                        style: TextStyles.darkRegular12.copyWith(
                          color: AppColors.greyColor3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.north_east, size: 17.sp, color: AppColors.greyColor5),
          ],
        ),
      ),
    );
  }
}

/// سؤال شائع بيتفتح بالضغط عليه
class _FaqTile extends StatefulWidget {
  final LegalSection section;

  const _FaqTile({required this.section});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(14.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              child: Row(
                children: [
                  Expanded(
                    child: LocalizedLabel(
                      text: widget.section.titleKey,
                      maxLines: 2,
                      style: TextStyles.boldStyle(14, weight: FontWeight.w600),
                    ),
                  ),
                  Gap(10.w),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 22.sp,
                      color: AppColors.greyColor4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // الإجابة بتظهر بس لما السؤال يتفتح
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.18),
                  ),
                  Gap(10.h),
                  LocalizedLabel(
                    text: widget.section.bodyKey,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    style: TextStyles.darkRegular14.copyWith(
                      color: AppColors.greyColor3,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
