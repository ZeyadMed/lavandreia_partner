import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/string_extension.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view/widgets/driver_accreditation_badges.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/driver_stats.dart';
import 'package:lavanderia_partner/features/trips/data/models/vehicle_kind.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/driver_profile_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// كارت الدليفري المتعيّن على الرحلة بعد ما المغسلة وافقت عليه
/// وتحت اسمه المغاسل اللي معتمداه
class AssignedDriverCard extends StatelessWidget {
  final DeliveryTrip trip;

  /// بعد الاعتماد السريع، عشان صفحة الطلب تجيبه تاني بالاعتماد الجديد
  final VoidCallback? onAccredited;

  const AssignedDriverCard({super.key, required this.trip, this.onAccredited});

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      titleKey: trip.type == DeliveryTripType.pickup
          ? 'pickup_driver'
          : 'dropoff_driver',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DriverTile.fromTrip(trip),
          Gap(10.h),
          DriverAccreditationBadges(
            laundries: trip.driverAccreditedBy,
            driverPhone: trip.driverPhone,
            onAccredited: onAccredited == null ? null : (_) => onAccredited!(),
          ),
          // صور الهدوم وقت الاستلام من العميل، بترجع المغسلة ليها وهي بتطابق
          if (trip.photoUrls.isNotEmpty) ...[
            Gap(12.h),
            TripPhotosStrip(photoUrls: trip.photoUrls),
          ],
        ],
      ),
    );
  }
}

/// صور الهدوم اللي الدليفري رفعها، والضغط على أي صورة بيفتحها بالحجم الكامل
class TripPhotosStrip extends StatelessWidget {
  final List<String> photoUrls;
  final String labelKey;

  const TripPhotosStrip({
    super.key,
    required this.photoUrls,
    this.labelKey = 'clothes_photos',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LocalizedLabel(
          text: labelKey,
          style: TextStyles.darkRegular12.copyWith(color: AppColors.greyColor4),
        ),
        Gap(8.h),
        SizedBox(
          height: 64.w,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photoUrls.length,
            separatorBuilder: (_, _) => Gap(8.w),
            itemBuilder: (context, index) {
              final url = photoUrls[index];
              return GestureDetector(
                onTap: () => _showPhoto(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 64.w,
                    height: 64.w,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: AppColors.semiWhiteColor3),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.semiWhiteColor3,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// الصورة بالحجم الكامل وتتكبر بالصوابع
  void _showPhoto(BuildContext context, String url) {
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

/// سطر الدليفري: صورته واسمه وتحته التليفون ونوع المركبة، وبعدهم ماركتها
/// وموديلها، وتحت السطر تقييمه وعدد رحلاته ومن إمتى على التطبيق
/// الضغط على أيقونة التليفون بيفتح الاتصال
/// [trailing] للزراير اللي على الطرف التاني زي القبول والرفض
class DriverTile extends StatelessWidget {
  final String name;
  final String phone;
  final String vehicleType;

  /// زي "Kia Picanto • 2018"
  final String vehicleDescription;
  final String? imageUrl;
  final DriverStats stats;
  final Widget? trailing;

  const DriverTile({
    super.key,
    required this.name,
    this.phone = '',
    this.vehicleType = '',
    this.vehicleDescription = '',
    this.imageUrl,
    this.stats = const DriverStats(),
    this.trailing,
  });

  /// الدليفري المتعيّن على الرحلة بكل بياناته
  DriverTile.fromTrip(DeliveryTrip trip, {Key? key, Widget? trailing})
    : this(
        key: key,
        name: trip.driverName,
        phone: trip.driverPhone,
        vehicleType: trip.vehicleType,
        vehicleDescription: trip.vehicleDescription,
        imageUrl: trip.driverImageUrl,
        stats: trip.driverStats,
        trailing: trailing,
      );

  @override
  Widget build(BuildContext context) {
    final vehicle = VehicleKind.fromApi(vehicleType);
    final vehicleLabel = vehicle == VehicleKind.other
        ? vehicleType
        : vehicle.labelKey.tr();
    final subtitle = [
      phone.forceLtr,
      vehicleLabel,
    ].where((text) => text.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DriverPhoto(
              imageUrl: imageUrl,
              fallbackIcon: vehicle.icon,
              size: 46,
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    text: name,
                    maxLines: 1,
                    style: TextStyles.boldStyle(15, weight: FontWeight.w700),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    Gap(3.h),
                    Label(
                      text: subtitle.join(' • '),
                      maxLines: 1,
                      style: TextStyles.darkRegular12.copyWith(
                        color: AppColors.greyColor4,
                      ),
                    ),
                  ],
                  if (vehicleDescription.isNotEmpty) ...[
                    Gap(2.h),
                    Label(
                      text: vehicleDescription,
                      maxLines: 1,
                      style: TextStyles.darkRegular12.copyWith(
                        color: AppColors.greyColor4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (phone.isNotEmpty)
              IconButton(
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                icon: Icon(
                  Icons.phone_rounded,
                  size: 20.sp,
                  color: AppColors.primaryColor,
                ),
              ),
            ?trailing,
          ],
        ),
        if (!stats.isEmpty) ...[Gap(10.h), DriverStatsRow(stats: stats)],
      ],
    );
  }
}
