import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// الكارت الأبيض اللي بيلف مجموعة صفوف في صفحة حسابي
class ProfileCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(children: children),
    );
  }
}

/// صف بيانات: الأيقونة على الجنب والعنوان فوق القيمة
/// بيتستخدم في كارت بيانات التواصل
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  final String value;

  /// آخر صف في الكارت مابيتحطش تحته خط
  final bool showDivider;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.labelKey,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, size: 20.sp, color: AppColors.primaryColor),
              Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedLabel(
                      text: labelKey,
                      style: TextStyles.darkRegular12.copyWith(
                        color: AppColors.greyColor3,
                      ),
                    ),
                    Gap(3.h),
                    Label(
                      text: value.isEmpty ? '—' : value,
                      maxLines: 2,
                      style: TextStyles.boldStyle(14, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const _RowDivider(),
      ],
    );
  }
}

/// صف قابل للضغط بسهم، بيتستخدم في ليستة الإعدادات
class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;
  final bool showDivider;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    // السهم بيتقلب مع اتجاه اللغة لوحده
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(icon, size: 20.sp, color: AppColors.primaryColor),
                Gap(14.w),
                Expanded(
                  child: LocalizedLabel(
                    text: labelKey,
                    maxLines: 1,
                    style: TextStyles.boldStyle(15, weight: FontWeight.w500),
                  ),
                ),
                Icon(
                  isRtl ? Icons.chevron_left : Icons.chevron_right,
                  size: 22.sp,
                  color: AppColors.greyColor5,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const _RowDivider(),
      ],
    );
  }
}

/// الخط الفاصل بين الصفوف، بيبعد عن الحواف زي الديزاين
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.16)),
    );
  }
}
