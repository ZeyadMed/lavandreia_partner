import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_profile.dart';

/// الهيدر الأزرق في صفحة حسابي: صورة المغسلة والاسم واسم المسؤول
/// وتحتهم شارة حالة العمل
class ProfileHeader extends StatelessWidget {
  final LaundryProfile profile;

  const ProfileHeader({super.key, required this.profile});

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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
      ),
      child: Column(
        children: [
          _ProfileAvatar(
            image: profile.coverImage,
            imageUrl: profile.coverImageUrl,
          ),
          Gap(12.h),
          Label(
            text: profile.laundryName,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyles.whiteText(20, weight: FontWeight.w800),
          ),
          Gap(4.h),
          Label(
            text: profile.ownerName,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyles.whiteText(
              13,
              weight: FontWeight.w400,
            ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Gap(14.h),
          _AvailabilityBadge(isAvailable: profile.isAvailable),
        ],
      ),
    );
  }
}

/// صورة المغسلة المربعة اللي فوق
/// بتعرض الصورة المحلية لو اليوزر غيّرها، وإلا اللي من السيرفر، وإلا اللوجو
class _ProfileAvatar extends StatelessWidget {
  final File? image;
  final String? imageUrl;

  const _ProfileAvatar({required this.image, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74.w,
      height: 74.w,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (image != null) {
      return Image.file(
        image!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() => Container(
    color: Colors.white.withValues(alpha: 0.15),
    alignment: Alignment.center,
    child: Padding(
      padding: EdgeInsets.all(6.w),
      child: Image.asset(
        Assets.assetsImagesLogo,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.local_laundry_service_outlined,
          color: Colors.white,
          size: 26.sp,
        ),
      ),
    ),
  );
}

/// شارة "متاح للعمل" اللي تحت الاسم
class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.greenColor : AppColors.redColor2,
              shape: BoxShape.circle,
            ),
          ),
          Gap(8.w),
          LocalizedLabel(
            text: isAvailable ? 'available_for_work' : 'unavailable_for_work',
            style: TextStyles.whiteText(13, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
