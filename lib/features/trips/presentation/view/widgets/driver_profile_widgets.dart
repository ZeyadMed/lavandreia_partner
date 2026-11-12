import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/trips/data/models/driver_stats.dart';

/// صورة الدليفري، والضغط عليها بيفتحها بالحجم الكامل عشان المغسلة تتعرف عليه
/// لو مفيش صورة أو فشلت بتظهر [fallbackIcon]
class DriverPhoto extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double size;

  const DriverPhoto({
    super.key,
    required this.imageUrl,
    this.fallbackIcon = Icons.delivery_dining_rounded,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.primaryColor.withValues(alpha: 0.1),
      child: Icon(
        fallbackIcon,
        color: AppColors.primaryColor,
        size: (size * 0.46).sp,
      ),
    );
    final url = imageUrl;

    return GestureDetector(
      onTap: url == null ? null : () => _showFull(context, url),
      child: ClipOval(
        child: SizedBox(
          width: size.w,
          height: size.w,
          child: url == null
              ? placeholder
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }

  /// الصورة بالحجم الكامل وتتكبر بالصوابع
  void _showFull(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(16.w),
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// تقييم الدليفري وعدد رحلاته ومن إمتى على التطبيق في سطر واحد
/// كل جزء بيستخبى لو السيرفر مابعتهوش، والسطر كله لو مفيش ولا واحد
class DriverStatsRow extends StatelessWidget {
  final DriverStats stats;

  const DriverStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final totalTrips = stats.totalTrips;
    final joinedAt = stats.joinedAt;

    return Wrap(
      spacing: 14.w,
      runSpacing: 6.h,
      children: [
        if (stats.hasRating) _ratingItem(),
        if (totalTrips != null)
          _StatItem(
            icon: Icons.route_rounded,
            text: 'driver_trips_count'.plural(totalTrips),
          ),
        if (joinedAt != null)
          _StatItem(
            icon: Icons.calendar_month_rounded,
            text: 'driver_member_since'.tr(
              args: [
                DateFormat.yMMM(context.locale.toString())
                    .format(joinedAt.toLocal()),
              ],
            ),
          ),
      ],
    );
  }

  /// "4.8 (23)"، أو "جديد" لو محدش قيّمه لسه
  Widget _ratingItem() {
    if (stats.isNew) {
      return _StatItem(
        icon: Icons.star_outline_rounded,
        iconColor: const Color(0xffF5A623),
        text: 'driver_new'.tr(),
      );
    }
    final count = stats.reviewsCount;
    return _StatItem(
      icon: Icons.star_rounded,
      iconColor: const Color(0xffF5A623),
      text: (stats.rating ?? 0).toStringAsFixed(1),
      suffix: count == null ? null : '($count)',
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  final String? suffix;

  const _StatItem({
    required this.icon,
    required this.text,
    this.iconColor,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15.sp, color: iconColor ?? AppColors.greyColor2),
        Gap(4.w),
        Label(
          text: text,
          maxLines: 1,
          style: TextStyles.darkRegular12.copyWith(
            color: AppColors.greyColor2,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (suffix != null) ...[
          Gap(3.w),
          Label(
            text: suffix!,
            maxLines: 1,
            style: TextStyles.darkRegular12.copyWith(
              color: AppColors.greyColor4,
            ),
          ),
        ],
      ],
    );
  }
}
