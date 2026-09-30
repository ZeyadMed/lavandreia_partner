import 'package:cached_network_image/cached_network_image.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DriverTile(name: trip.driverName, phone: trip.driverPhone),
          // صور الهدوم وقت الاستلام من العميل، بترجع المغسلة ليها وهي بتطابق
          if (trip.photoUrls.isNotEmpty) ...[
            Gap(12.h),
            LocalizedLabel(
              text: 'clothes_photos',
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.greyColor4,
              ),
            ),
            Gap(8.h),
            SizedBox(
              height: 64.w,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trip.photoUrls.length,
                separatorBuilder: (_, _) => Gap(8.w),
                itemBuilder: (context, index) {
                  final url = trip.photoUrls[index];
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
        ],
      ),
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
