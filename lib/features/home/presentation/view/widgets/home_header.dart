import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/flexiable_image.dart';
import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';

/// هيدر الصفحة الرئيسية: الترحيب واسم المغسلة وعنوانها وصورتها
/// الـ profile بيبقى null لحد ما الريكوست يرجع، فبنعرض مكانه بلوكات فاضية
class HomeHeader extends StatelessWidget {
  final PartnerProfile? profile;

  const HomeHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final address = profile?.address.trim() ?? '';
    final subtitleStyle = TextStyles.whiteText(
      12,
      weight: FontWeight.w400,
    ).copyWith(color: Colors.white.withValues(alpha: 0.8));

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LocalizedLabel(
                      text: 'home_greeting',
                      style: TextStyles.whiteText(
                        13,
                        weight: FontWeight.w400,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    Gap(4.w),
                    Text('👋', style: TextStyle(fontSize: 13.sp)),
                  ],
                ),
                Gap(6.h),
                if (profile == null)
                  _PlaceholderLine(width: 160.w, height: 22.h)
                else
                  Label(
                    text: profile!.name,
                    maxLines: 1,
                    style: TextStyles.whiteText(22, weight: FontWeight.w800),
                  ),
                Gap(6.h),
                if (profile == null)
                  _PlaceholderLine(width: 200.w, height: 12.h)
                else if (address.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      Gap(4.w),
                      Expanded(
                        child: Label(
                          text: address,
                          maxLines: 1,
                          style: subtitleStyle,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Gap(12.w),
          _LaundryImage(imageUrl: profile?.imageUrl),
        ],
      ),
    );
  }
}

/// صورة المغسلة، ولو مفيش صورة بنعرض اللوجو مكانها
class _LaundryImage extends StatelessWidget {
  final String? imageUrl;

  const _LaundryImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return Container(
      width: 64.w,
      height: 64.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? FlexibleImage(source: url, width: 64.w, height: 64.w)
          : Padding(
              padding: EdgeInsets.all(8.w),
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
    );
  }
}

/// بلوك فاضي بياخد مكان النص وهو بيحمّل
class _PlaceholderLine extends StatelessWidget {
  final double width;
  final double height;

  const _PlaceholderLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6.r),
      ),
    );
  }
}
