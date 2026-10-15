import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accredited_driver.dart';
import 'package:url_launcher/url_launcher.dart';

/// كارت دليفري معتمد: الصورة والاسم والرقم وزرار الاتصال،
/// وتحتهم تاريخ الاعتماد وزرار إلغائه
class AccreditedDriverCard extends StatelessWidget {
  final AccreditedDriver driver;

  /// ريكوست الإلغاء شغال على الدليفري ده
  final bool isRemoving;

  /// null وفيه ريكوست إلغاء شغال على دليفري تاني
  final VoidCallback? onUnaccredit;

  const AccreditedDriverCard({
    super.key,
    required this.driver,
    required this.onUnaccredit,
    this.isRemoving = false,
  });

  @override
  Widget build(BuildContext context) {
    final accreditedAt = driver.accreditedAt;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightGreyColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _DriverAvatar(imageUrl: driver.profileImageUrl),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Label(
                      text: driver.fullName,
                      maxLines: 1,
                      style: TextStyles.boldStyle(15, weight: FontWeight.w700),
                    ),
                    if (driver.phoneNumber.isNotEmpty) ...[
                      Gap(3.h),
                      // الرقم بيتكتب من الشمال لليمين عشان +218 مايتنقلش لآخره
                      Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Label(
                          text: driver.phoneNumber,
                          maxLines: 1,
                          style: TextStyles.darkRegular12.copyWith(
                            color: AppColors.greyColor4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (driver.phoneNumber.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: driver.phoneNumber)),
                  icon: Icon(
                    Icons.phone_rounded,
                    size: 20.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
            ],
          ),
          Gap(10.h),
          Row(
            children: [
              if (accreditedAt != null) ...[
                Icon(
                  Icons.event_available_rounded,
                  size: 14.sp,
                  color: AppColors.greyColor3,
                ),
                Gap(4.w),
              ],
              Expanded(
                child: accreditedAt == null
                    ? const SizedBox.shrink()
                    : Label(
                        text: 'accredited_at'.tr(
                          args: [
                            DateFormat(
                              'd MMM yyyy',
                              context.locale.toString(),
                            ).format(accreditedAt),
                          ],
                        ),
                        maxLines: 1,
                        style: TextStyles.darkRegular12.copyWith(
                          color: AppColors.greyColor3,
                        ),
                      ),
              ),
              _UnaccreditButton(isLoading: isRemoving, onTap: onUnaccredit),
            ],
          ),
        ],
      ),
    );
  }
}

/// صورة الدليفري، ولو مفيش صورة أو فشلت بتظهر أيقونة افتراضية
class _DriverAvatar extends StatelessWidget {
  final String? imageUrl;

  const _DriverAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.primaryColor,
        size: 24.sp,
      ),
    );
    final url = imageUrl;

    return ClipOval(
      child: SizedBox(
        width: 46.w,
        height: 46.w,
        child: url == null || url.isEmpty
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _UnaccreditButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _UnaccreditButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: Opacity(
        opacity: onTap == null && !isLoading ? 0.5 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.redColor2.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: isLoading
              ? SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.redColor2,
                  ),
                )
              : LocalizedLabel(
                  text: 'unaccredit_driver',
                  maxLines: 1,
                  style: TextStyles.boldStyle(
                    12,
                    color: AppColors.redColor2,
                    weight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
