import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/helpers/bottom_sheet.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/session/current_laundry.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/accredited_drivers_data_source.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accrediting_laundry.dart';
import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';

const _mineBackground = Color(0xffE3F5EA);
const _mineForeground = Color(0xff0E8C4F);

/// المغاسل اللي معتمدة الدليفري كشيبس تحت اسمه في كارت الطلب أو الرحلة
/// "معتمد لديك" الأول بلون مميز، وبعده أول [maxVisible] مغاسل و "+N" للباقي
/// ومن غير [onAccredited] مفيش زرار الاعتماد السريع
class DriverAccreditationBadges extends StatelessWidget {
  final List<AccreditingLaundry> laundries;

  /// الرقم اللي بيتبعت في الاعتماد السريع
  final String driverPhone;

  /// بتتنادى بالمغسلة الحالية بعد ما الاعتماد السريع ينجح
  final ValueChanged<AccreditingLaundry>? onAccredited;

  static const int maxVisible = 2;

  const DriverAccreditationBadges({
    super.key,
    required this.laundries,
    this.driverPhone = '',
    this.onAccredited,
  });

  @override
  Widget build(BuildContext context) {
    // البروفايل ممكن يوصل بعد الكارت، فبنسمع عليه عشان "معتمد لديك" يظهر
    return ValueListenableBuilder<PartnerProfile?>(
      valueListenable: CurrentLaundry.profile,
      builder: (context, profile, _) {
        final currentId = profile?.id;
        final isMine = laundries.isAccreditedBy(currentId);
        final others = [
          for (final laundry in laundries)
            if (laundry.laundryId != currentId) laundry,
        ];
        final hiddenCount = others.length - maxVisible;
        final canAccredit =
            onAccredited != null &&
            profile != null &&
            !isMine &&
            driverPhone.isNotEmpty;

        return Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isMine) const _MineChip(),
            for (final laundry in others.take(maxVisible))
              _LaundryChip(name: laundry.laundryName),
            if (hiddenCount > 0)
              _MoreChip(
                count: hiddenCount,
                onTap: () => _showAll(context, currentId),
              ),
            if (laundries.isEmpty) const _NotAccreditedLabel(),
            if (canAccredit)
              _QuickAccreditButton(
                driverPhone: driverPhone,
                laundry: AccreditingLaundry(
                  laundryId: profile.id,
                  laundryName: profile.name,
                ),
                onAccredited: onAccredited!,
              ),
          ],
        );
      },
    );
  }

  /// كل المغاسل، والمغسلة الحالية الأول
  void _showAll(BuildContext context, int? currentId) {
    final sorted = [
      for (final laundry in laundries)
        if (laundry.laundryId == currentId) laundry,
      for (final laundry in laundries)
        if (laundry.laundryId != currentId) laundry,
    ];
    showAppBottomSheet<void>(
      context: context,
      title: 'accredited_by_laundries'.tr(),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => Gap(8.h),
        itemBuilder: (context, index) {
          final laundry = sorted[index];
          final isMine = laundry.laundryId == currentId;
          return Row(
            children: [
              Icon(
                isMine
                    ? Icons.verified_rounded
                    : Icons.local_laundry_service_outlined,
                size: 20.sp,
                color: isMine ? _mineForeground : AppColors.greyColor3,
              ),
              Gap(10.w),
              Expanded(
                child: Label(
                  text: laundry.laundryName,
                  maxLines: 1,
                  style: TextStyles.darkRegular14,
                ),
              ),
              if (isMine) const _MineChip(),
            ],
          );
        },
      ),
    );
  }
}

class _MineChip extends StatelessWidget {
  const _MineChip();

  @override
  Widget build(BuildContext context) {
    return _Chip(
      background: _mineBackground,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 13.sp, color: _mineForeground),
          Gap(4.w),
          LocalizedLabel(
            text: 'accredited_by_you',
            maxLines: 1,
            style: TextStyles.boldStyle(
              11,
              color: _mineForeground,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaundryChip extends StatelessWidget {
  final String name;

  const _LaundryChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return _Chip(
      background: AppColors.semiWhiteColor3,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_laundry_service_outlined,
            size: 13.sp,
            color: AppColors.greyColor2,
          ),
          Gap(4.w),
          // الأسامي الطويلة بتتقص عشان الشيب مايكسرش السطر
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 120.w),
            child: Label(
              text: name,
              maxLines: 1,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.greyColor2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MoreChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _Chip(
        background: AppColors.primaryColor.withValues(alpha: 0.08),
        child: Label(
          text: 'more_count'.tr(args: ['$count']),
          maxLines: 1,
          style: TextStyles.darkRegular12.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NotAccreditedLabel extends StatelessWidget {
  const _NotAccreditedLabel();

  @override
  Widget build(BuildContext context) {
    return LocalizedLabel(
      text: 'not_accredited',
      maxLines: 1,
      style: TextStyles.darkRegular12.copyWith(color: AppColors.greyColor4),
    );
  }
}

class _Chip extends StatelessWidget {
  final Color background;
  final Widget child;

  const _Chip({required this.background, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: child,
    );
  }
}

/// "اعتماد هذا السائق" بيبعت رقمه لـ POST accredited-drivers
/// واللودينج محلي عشان كل كارت ليه زراره
class _QuickAccreditButton extends StatefulWidget {
  final String driverPhone;

  /// المغسلة الحالية، بتتبعت لـ [onAccredited] بعد النجاح
  final AccreditingLaundry laundry;
  final ValueChanged<AccreditingLaundry> onAccredited;

  const _QuickAccreditButton({
    required this.driverPhone,
    required this.laundry,
    required this.onAccredited,
  });

  @override
  State<_QuickAccreditButton> createState() => _QuickAccreditButtonState();
}

class _QuickAccreditButtonState extends State<_QuickAccreditButton> {
  bool _isLoading = false;

  Future<void> _accredit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await getIt<AccreditedDriversDataSource>().accreditDriver(
      widget.driverPhone,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isError) {
      final failure = result.throwError();
      // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
      if (failure is ServerFailure ||
          failure is UnknownFailure ||
          failure is ParsingFailure) {
        context.showErrorMessage(failure.message);
      }
      return;
    }
    context.showSuccessMessage('driver_accredited_success'.tr());
    widget.onAccredited(widget.laundry);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isLoading ? null : _accredit,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLoading
                ? SizedBox(
                    width: 12.sp,
                    height: 12.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: AppColors.primaryColor,
                    ),
                  )
                : Icon(
                    Icons.verified_outlined,
                    size: 13.sp,
                    color: AppColors.primaryColor,
                  ),
            Gap(4.w),
            LocalizedLabel(
              text: 'accredit_this_driver',
              maxLines: 1,
              style: TextStyles.boldStyle(
                11,
                color: AppColors.primaryColor,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
