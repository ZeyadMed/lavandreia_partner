import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';

/// تايم لاين مراحل الطلب
/// المراحل اللي عدت بتبقى دايرة زرقا فيها علامة صح، واللي لسه رمادية
class OrderTimeline extends StatelessWidget {
  /// آخر مرحلة وصلها الطلب
  final PartnerOrderStage currentStage;

  const OrderTimeline({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final stages = PartnerOrderStage.values;

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isDone = index <= currentStage.index;
        // الخط الواصل بين الدايرة واللي بعدها
        final isLineActive = index < currentStage.index;

        return IntrinsicHeight(
          // بنثبّت اتجاه الصف LTR عشان الدواير تفضل على الشمال
          // واسم المرحلة على اليمين، حتى والتطبيق عربي (RTL)
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // العمود بتاع الدواير والخطوط
              Column(
                children: [
                  _StageDot(isDone: isDone),
                  if (index != stages.length - 1)
                    Expanded(
                      child: Container(
                        width: 2.w,
                        margin: EdgeInsets.symmetric(vertical: 2.h),
                        color: isLineActive
                            ? AppColors.primaryColor
                            : AppColors.semiWhiteColor2,
                      ),
                    ),
                ],
              ),
              Gap(12.w),
              // اسم المرحلة، بيبهت لو لسه ماوصلناهاش
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == stages.length - 1 ? 0 : 18.h,
                  ),
                  child: LocalizedLabel(
                    text: stage.labelKey,
                    // النص لازق في الدواير اللي على شماله
                    textAlign: TextAlign.right,
                    style: TextStyles.boldStyle(
                      14,
                      color: isDone
                          ? AppColors.darkTextColor
                          : AppColors.greyColor5,
                      weight: isDone ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// دايرة المرحلة الواحدة
class _StageDot extends StatelessWidget {
  final bool isDone;

  const _StageDot({required this.isDone});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primaryColor : AppColors.semiWhiteColor2,
        shape: BoxShape.circle,
      ),
      child: isDone
          ? Icon(Icons.check, size: 14.sp, color: AppColors.whiteColor)
          : null,
    );
  }
}
