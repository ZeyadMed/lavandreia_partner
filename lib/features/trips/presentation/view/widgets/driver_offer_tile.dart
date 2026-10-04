import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/features/trips/data/models/vehicle_kind.dart';
import 'package:lavanderia_partner/features/trips/presentation/view_model/trips_cubits.dart';
import 'package:url_launcher/url_launcher.dart';

/// كارت عرض دليفري واحد: الاسم وزرار الاتصال، وتحتهم نوع المركبة وبعده عن
/// المغسلة والوقت المتوقع لوصوله، وتحت خالص زرار القبول والرفض
/// من غير [onApprove] (الدليفري اللي اتوافق عليه) بيظهر [trailing] بدل الزراير
class DriverOfferTile extends StatelessWidget {
  final TripRequest request;

  /// أقرب واحد لما يبقى فيه أكتر من عرض
  final bool isClosest;

  /// الزرار اللي بيحمّل على العرض ده بالذات
  final TripRequestAction? loadingAction;

  /// فيه ريكوست شغال على أي عرض في نفس الرحلة
  final bool isBusy;

  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final Widget? trailing;

  const DriverOfferTile({
    super.key,
    required this.request,
    this.isClosest = false,
    this.loadingAction,
    this.isBusy = false,
    this.onApprove,
    this.onReject,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = request.vehicleKind;
    final vehicleLabel = vehicle == VehicleKind.other
        ? request.vehicleType
        : vehicle.labelKey.tr();
    final distance = request.distanceKm;
    final eta = request.etaMinutes;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isClosest
              ? AppColors.primaryColor.withValues(alpha: 0.5)
              : AppColors.lightGreyColor,
          width: isClosest ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  vehicle.icon,
                  color: AppColors.primaryColor,
                  size: 22.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Label(
                  text: request.driverName,
                  maxLines: 1,
                  style: TextStyles.boldStyle(15, weight: FontWeight.w700),
                ),
              ),
              if (isClosest) ...[Gap(6.w), const _ClosestChip()],
              if (request.driverPhone.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: request.driverPhone)),
                  icon: Icon(
                    Icons.phone_rounded,
                    size: 20.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ?trailing,
            ],
          ),
          Gap(10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              if (vehicleLabel.isNotEmpty)
                _InfoChip(icon: vehicle.icon, text: vehicleLabel),
              if (distance != null)
                _InfoChip(
                  icon: Icons.place_outlined,
                  text: _formatDistance(distance),
                ),
              if (eta != null)
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  text: 'offer_eta'.tr(args: ['$eta']),
                  isHighlighted: true,
                ),
            ],
          ),
          if (onApprove != null && onReject != null) ...[
            Gap(12.h),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    isLoading: loadingAction == TripRequestAction.approve,
                    color: AppColors.primaryColor,
                    filled: true,
                    onTap: isBusy ? null : onApprove,
                    child: LocalizedLabel(
                      text: 'approve',
                      style: TextStyles.boldStyle(
                        14,
                        color: AppColors.whiteColor,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Gap(8.w),
                _ActionButton(
                  isLoading: loadingAction == TripRequestAction.reject,
                  color: AppColors.redColor2,
                  width: 44.h,
                  onTap: isBusy ? null : onReject,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20.sp,
                    color: AppColors.redColor2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// أقل من كيلو بالمتر، ومن 10 كيلو وطالع من غير كسور
  static String _formatDistance(double km) {
    if (km < 1) {
      return 'offer_distance_m'.tr(args: ['${(km * 1000).round()}']);
    }
    final text = km >= 10 ? '${km.round()}' : km.toStringAsFixed(1);
    return 'offer_distance_km'.tr(args: [text]);
  }
}

/// شيب صغير: أيقونة + نص، والوقت المتوقع بلون مميز
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isHighlighted;

  const _InfoChip({
    required this.icon,
    required this.text,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHighlighted ? AppColors.primaryColor : AppColors.greyColor2;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : AppColors.semiWhiteColor3,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          Gap(4.w),
          Label(
            text: text,
            maxLines: 1,
            style: TextStyles.darkRegular12.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosestChip extends StatelessWidget {
  const _ClosestChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xffE3F5EA),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: LocalizedLabel(
        text: 'offer_closest',
        style: TextStyles.boldStyle(
          11,
          color: const Color(0xff0E8C4F),
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// زرار القبول المليان أو زرار الرفض الفاتح، وبيعرض لودينج مكان المحتوى
class _ActionButton extends StatelessWidget {
  final bool isLoading;
  final Color color;
  final bool filled;
  final double? width;
  final VoidCallback? onTap;
  final Widget child;

  const _ActionButton({
    required this.isLoading,
    required this.color,
    required this.onTap,
    required this.child,
    this.filled = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: filled ? AppColors.whiteColor : color,
                ),
              )
            : child,
      ),
    );
  }
}
