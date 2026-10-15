import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/session/current_laundry.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/accredited_drivers_data_source.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accrediting_laundry.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view/widgets/driver_accreditation_badges.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/driver_tile.dart';

/// الدليفري اللي على الرحلة ينفع يتعتمد: عليه رقم ومش معتمد عند المغسلة
/// والمغسلة الحالية معروفة
bool canAccreditTripDriver(DeliveryTrip trip) =>
    CurrentLaundry.id != null &&
    trip.hasDriver &&
    trip.driverPhone.isNotEmpty &&
    !trip.driverAccreditedBy.isAccreditedBy(CurrentLaundry.id);

/// بيتعرض في نهاية الرحلة: الهدوم وصلت المغسلة أو وصلت العميل
/// بيسأل المغسلة تعتمد الدليفري ولا لأ، وبيرجّع true لو اتعتمد
Future<bool?> showAccreditTripDriverSheet({
  required BuildContext context,
  required DeliveryTrip trip,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AccreditTripDriverSheet(trip: trip),
  );
}

class _AccreditTripDriverSheet extends StatefulWidget {
  final DeliveryTrip trip;

  const _AccreditTripDriverSheet({required this.trip});

  @override
  State<_AccreditTripDriverSheet> createState() =>
      _AccreditTripDriverSheetState();
}

class _AccreditTripDriverSheetState extends State<_AccreditTripDriverSheet> {
  bool _isLoading = false;

  /// رسالة السيرفر لو الاعتماد فشل، جوه الشيت لأن الـ snackbar بيستخبى وراه
  String? _error;

  Future<void> _accredit() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await getIt<AccreditedDriversDataSource>().accreditDriver(
      widget.trip.driverPhone,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    final failure = result.throwError();
    setState(() {
      _isLoading = false;
      // انتهاء الجلسة بيرجّع للوجين لوحده فمالوش رسالة هنا
      if (failure is! UnauthorizedFailure) _error = failure.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final isPickup = trip.type == DeliveryTripType.pickup;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // المقبض الرمادي الصغير فوق
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.semiWhiteColor2,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Gap(18.h),
          Center(
            child: Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_outlined,
                size: 26.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Gap(14.h),
          LocalizedLabel(
            text: isPickup
                ? 'trip_finished_pickup_title'
                : 'trip_finished_dropoff_title',
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18, weight: FontWeight.w800),
          ),
          Gap(6.h),
          Label(
            text: 'accredit_trip_driver_message'.tr(args: [trip.driverName]),
            textAlign: TextAlign.center,
            maxLines: 3,
            style: TextStyles.darkRegular14.copyWith(
              color: AppColors.greyColor3,
            ),
          ),
          Gap(16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.semiWhiteColor3,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DriverTile(name: trip.driverName, phone: trip.driverPhone),
                Gap(8.h),
                DriverAccreditationBadges(laundries: trip.driverAccreditedBy),
              ],
            ),
          ),
          if (_error != null) ...[
            Gap(10.h),
            Label(
              text: _error!,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.redColor,
              ),
            ),
          ],
          Gap(18.h),
          CustomButton(
            // بنقفل الضغط وقت الإرسال عشان مايتبعتش مرتين
            onPressed: _isLoading ? () {} : _accredit,
            title: _isLoading ? 'accrediting' : 'accredit_this_driver',
            backgroundColor: _isLoading
                ? AppColors.primaryColor.withValues(alpha: 0.6)
                : AppColors.primaryColor,
          ),
          Gap(4.h),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pop(false),
            child: LocalizedLabel(
              text: 'later',
              style: TextStyles.darkBold14.copyWith(
                color: AppColors.greyColor3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
