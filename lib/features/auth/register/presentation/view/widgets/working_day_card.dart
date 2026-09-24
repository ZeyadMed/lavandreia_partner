import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';

/// كارت يوم واحد في مواعيد العمل: اسم اليوم وسويتش "مغلق"
/// ولو مفتوح بيظهر تحته "من" و "إلى"
/// بيتستخدم في خطوة التسجيل وفي صفحة تعديل المواعيد
class WorkingDayCard extends StatelessWidget {
  final WorkingDay day;
  final bool hasError;
  final ValueChanged<bool> onClosedChanged;
  final VoidCallback onPickOpenTime;
  final VoidCallback onPickCloseTime;

  const WorkingDayCard({
    super.key,
    required this.day,
    required this.onClosedChanged,
    required this.onPickOpenTime,
    required this.onPickCloseTime,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: day.isClosed
              ? Colors.grey.withValues(alpha: 0.06)
              : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasError
                ? AppColors.redColor
                : day.isClosed
                ? Colors.grey.withValues(alpha: 0.25)
                : AppColors.primaryColor.withValues(alpha: 0.35),
            width: hasError ? 1.4 : 0.9,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LocalizedLabel(
                    text: day.key,
                    style: TextStyles.blackBold16.copyWith(
                      color: day.isClosed
                          ? AppColors.greyColor3
                          : AppColors.darkTextColor,
                    ),
                  ),
                ),
                LocalizedLabel(
                  text: 'closed',
                  style: TextStyles.darkRegular14.copyWith(
                    color: day.isClosed
                        ? AppColors.redColor
                        : AppColors.greyColor4,
                  ),
                ),
                Gap(4.w),
                Switch(
                  value: day.isClosed,
                  activeThumbColor: AppColors.redColor,
                  onChanged: onClosedChanged,
                ),
              ],
            ),
            // الساعات بتختفي خالص لما اليوم يبقى مقفول
            if (!day.isClosed) ...[
              Gap(6.h),
              Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      labelKey: 'from',
                      time: day.openTime,
                      onTap: onPickOpenTime,
                    ),
                  ),
                  Gap(10.w),
                  Expanded(
                    child: _TimeBox(
                      labelKey: 'to',
                      time: day.closeTime,
                      onTap: onPickCloseTime,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// خانة الوقت الواحدة: "من" أو "إلى" وتحتها الساعة المختارة
class _TimeBox extends StatelessWidget {
  final String labelKey;
  final DateTimeRangePart? time;
  final VoidCallback onTap;

  const _TimeBox({
    required this.labelKey,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(10.r),
          border: const Border.fromBorderSide(
            BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 16.sp,
              color: AppColors.primaryColor,
            ),
            Gap(6.w),
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
                  Label(
                    text: time?.toLocalizedString() ?? '--:--',
                    style: TextStyles.darkBold14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
