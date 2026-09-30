import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:url_launcher/url_launcher.dart';

/// كارت الدليفري المتعيّن على الرحلة بعد ما المغسلة وافقت عليه
class AssignedDriverCard extends StatelessWidget {
  final DeliveryTrip trip;

  const AssignedDriverCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      titleKey: trip.type == DeliveryTripType.pickup
          ? 'pickup_driver'
          : 'dropoff_driver',
      child: DriverTile(name: trip.driverName, phone: trip.driverPhone),
    );
  }
}

/// سطر الدليفري: الأفاتار والاسم وتحته التليفون ونوع العربية
/// الضغط على أيقونة التليفون بيفتح الاتصال
/// [trailing] للزراير اللي على الطرف التاني زي القبول والرفض
class DriverTile extends StatelessWidget {
  final String name;
  final String phone;
  final String vehicleType;
  final Widget? trailing;

  const DriverTile({
    super.key,
    required this.name,
    this.phone = '',
    this.vehicleType = '',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [phone, vehicleType].where((text) => text.isNotEmpty);

    return Row(
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delivery_dining_rounded,
            color: AppColors.primaryColor,
            size: 22.sp,
          ),
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
    );
  }
}
