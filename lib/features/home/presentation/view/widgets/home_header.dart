import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// هيدر الصفحة الرئيسية: الترحيب واسم المغسلة واللوجو
/// وتحته كارت تبديل حالة "متاح للعمل"
class HomeHeader extends StatelessWidget {
  final String laundryName;
  final bool isAvailable;
  final ValueChanged<bool> onAvailabilityChanged;

  const HomeHeader({
    super.key,
    required this.laundryName,
    required this.isAvailable,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        24.h,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LocalizedLabel(
                          text: 'home_greeting',
                          style:
                              TextStyles.whiteText(
                                13,
                                weight: FontWeight.w400,
                              ).copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                        ),
                        Gap(4.w),
                        Text('👋', style: TextStyle(fontSize: 13.sp)),
                      ],
                    ),
                    Gap(6.h),
                    Label(
                      text: laundryName,
                      maxLines: 1,
                      style: TextStyles.whiteText(22, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Gap(12.w),
              _LogoBadge(),
            ],
          ),
          Gap(20.h),
          _AvailabilityCard(
            isAvailable: isAvailable,
            onChanged: onAvailabilityChanged,
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // اللوجو عرضه أكبر من طوله، فالبادج مستطيلة مش مربعة عشان يبان بحجم مناسب.
    // والصورة نفسها حواليها هوامش شفافة، فبنقصها بـ OverflowBox عشان تملا البادج.
    return Container(
      width: 104.w,
      height: 54.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: SizedBox(
            width: 84.w,
            height: 84.w,
            child: Image.asset(
              Assets.assetsImagesLogo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.local_laundry_service_outlined,
                color: Colors.white,
                size: 26.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const _AvailabilityCard({required this.isAvailable, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? AppColors.greenColor
                            : AppColors.redColor2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Gap(8.w),
                    Label(
                      text: isAvailable
                          ? 'available_for_work'.tr()
                          : 'unavailable_for_work'.tr(),
                      style: TextStyles.whiteText(15, weight: FontWeight.w700),
                    ),
                  ],
                ),
                Gap(4.h),
                Label(
                  text: isAvailable
                      ? 'receiving_new_orders'.tr()
                      : 'not_receiving_new_orders'.tr(),
                  maxLines: 1,
                  style: TextStyles.whiteText(
                    12,
                    weight: FontWeight.w400,
                  ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Gap(12.w),
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            trackOutlineColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
