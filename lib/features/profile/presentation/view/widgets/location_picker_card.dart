import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// كارت تحديد الموقع على الخريطة
/// فاضي بيبان كدعوة للتحديد، وبعد الاختيار بيعرض العنوان والإحداثيات
class LocationPickerCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;

  /// العنوان النصي اللي رجع من الخريطة، ممكن يبقى فاضي
  final String? address;

  /// بيتحط بعد محاولة حفظ فاشلة عشان التحذير يظهر
  final bool hasError;

  final VoidCallback onTap;

  const LocationPickerCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.onTap,
    this.hasError = false,
  });

  bool get _hasLocation => latitude != null && longitude != null;

  String get _coordinates =>
      '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: hasError
                ? AppColors.redColor
                : _hasLocation
                ? AppColors.primaryColor
                : Colors.grey.withValues(alpha: 0.25),
            width: hasError || _hasLocation ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _hasLocation ? Icons.location_on : Icons.add_location_alt_outlined,
              size: 34.sp,
              color: _hasLocation
                  ? AppColors.primaryColor
                  : AppColors.greyColor3,
            ),
            Gap(10.h),
            LocalizedLabel(
              text: _hasLocation ? 'location_selected' : 'pick_location_on_map',
              textAlign: TextAlign.center,
              style: TextStyles.blackBold16,
            ),
            Gap(6.h),
            Label(
              text: _hasLocation
                  ? (address?.trim().isNotEmpty == true
                        ? address!.trim()
                        : _coordinates)
                  : 'pick_location_hint'.tr(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.greyColor3,
              ),
            ),
            if (_hasLocation) ...[
              Gap(10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Label(text: _coordinates, style: TextStyles.darkBold12),
              ),
              Gap(8.h),
              LocalizedLabel(
                text: 'tap_to_change_location',
                style: TextStyles.darkRegular12.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ],
            if (hasError) ...[
              Gap(10.h),
              LocalizedLabel(
                text: 'location_required',
                textAlign: TextAlign.center,
                style: TextStyles.darkBold12.copyWith(
                  color: AppColors.redColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
