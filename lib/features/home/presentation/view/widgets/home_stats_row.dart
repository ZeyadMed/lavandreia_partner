import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// الكروت الثلاثة البيضا اللي فوق في الرئيسية
/// الترتيب في العربي بيتقلب لوحده فـ"طلبات جديدة" بتظهر على اليمين
class HomeStatsRow extends StatelessWidget {
  final int completedToday;
  final int inProgress;
  final int newOrders;

  const HomeStatsRow({
    super.key,
    required this.completedToday,
    required this.inProgress,
    required this.newOrders,
  });

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight بيدي الصف ارتفاع محدد عشان stretch تشتغل جوه
    // SingleChildScrollView، من غيره الارتفاع بيبقى لانهائي والكروت متترسمش
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              value: completedToday,
              labelKey: 'stat_completed_today',
              valueColor: AppColors.greenColor,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: _StatCard(
              value: inProgress,
              labelKey: 'stat_in_progress',
              valueColor: AppColors.lightOrangeColor,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: _StatCard(
              value: newOrders,
              labelKey: 'stat_new_orders',
              valueColor: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String labelKey;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.labelKey,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Label(
            text: value.toString(),
            maxLines: 1,
            style: TextStyles.boldStyle(
              24,
              color: valueColor,
              weight: FontWeight.w800,
            ),
          ),
          Gap(6.h),
          LocalizedLabel(
            text: labelKey,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular12.copyWith(
              color: AppColors.greyColor2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
