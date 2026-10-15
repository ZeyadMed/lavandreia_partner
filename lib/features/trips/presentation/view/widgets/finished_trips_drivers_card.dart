import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view/widgets/driver_accreditation_badges.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/driver_tile.dart';

/// دليفرية الرحلات اللي خلصت في الطلب (الاستلام و/أو التسليم)
/// عشان المغسلة تقدر تعتمد أي واحد فيهم بعد ما الرحلة تخلص، حتى بعدين
class FinishedTripsDriversCard extends StatelessWidget {
  final List<DeliveryTrip> trips;

  /// بعد الاعتماد، عشان صفحة الطلب تجيبه تاني بالاعتماد الجديد
  final VoidCallback onAccredited;

  const FinishedTripsDriversCard({
    super.key,
    required this.trips,
    required this.onAccredited,
  });

  @override
  Widget build(BuildContext context) {
    return DetailsCard(
      titleKey: 'order_drivers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, trip) in trips.indexed) ...[
            if (index > 0)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Divider(height: 1, color: AppColors.lightGreyColor),
              ),
            LocalizedLabel(
              text: trip.type == DeliveryTripType.pickup
                  ? 'pickup_driver'
                  : 'dropoff_driver',
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.greyColor4,
              ),
            ),
            Gap(8.h),
            DriverTile(name: trip.driverName, phone: trip.driverPhone),
            Gap(10.h),
            DriverAccreditationBadges(
              laundries: trip.driverAccreditedBy,
              driverPhone: trip.driverPhone,
              onAccredited: (_) => onAccredited(),
            ),
          ],
        ],
      ),
    );
  }
}
