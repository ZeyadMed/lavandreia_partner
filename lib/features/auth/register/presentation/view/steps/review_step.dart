import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/common_widget/loading_button.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/register_section_card.dart';

/// الخطوة الأخيرة: عرض كل البيانات قبل إنشاء الحساب
/// كل قسم فيه زرار تعديل بيرجّع اليوزر لخطوته
class ReviewStep extends StatelessWidget {
  final RegisterData data;

  /// بيتنادى لما اليوزر يضغط "إنشاء حساب"
  final VoidCallback onSubmit;

  /// الزرار بيتقفل ويعرض لودينج لحد ما الريكوست يخلص
  final bool isSubmitting;

  /// بيرجّع اليوزر لخطوة معينة (بادئة من 1) لما يضغط تعديل
  final void Function(int step) onEditStep;

  const ReviewStep({
    super.key,
    required this.data,
    required this.onSubmit,
    required this.onEditStep,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLaundryInfo(),
        Gap(14.h),
        _buildLocation(),
        Gap(14.h),
        _buildWorkingHours(),
        Gap(22.h),
        isSubmitting
            ? const Center(child: LoadingButton())
            : CustomButton(onPressed: onSubmit, title: 'sign_up'.tr()),
      ],
    );
  }

  Widget _buildLaundryInfo() {
    return _SectionWithEdit(
      titleKey: 'laundry_info',
      onEdit: () => onEditStep(1),
      child: Column(
        children: [
          // الصورة إجبارية، بس بنتحقق برضه عشان الويدجت
          // ماتقعش لو اتفتحت بداتا ناقصة
          if (data.coverImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.file(
                data.coverImage!,
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            Gap(6.h),
          ],
          ReviewRow(labelKey: 'laundry_name', value: data.laundryName),
          ReviewRow(labelKey: 'laundry_phone', value: data.laundryPhone),
          ReviewRow(labelKey: 'owner_name', value: data.ownerName),
          ReviewRow(
            labelKey: 'owner_phone',
            value: data.ownerPhone,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return _SectionWithEdit(
      titleKey: 'location',
      onEdit: () => onEditStep(2),
      child: Column(
        children: [
          ReviewRow(labelKey: 'city', value: data.cityName ?? '—'),
          if (data.pickedAddress?.isNotEmpty == true)
            ReviewRow(
              labelKey: 'map_address',
              value: data.pickedAddress!,
            ),
          ReviewRow(
            labelKey: 'coordinates',
            value: data.hasLocationOnMap
                ? '${data.latitude!.toStringAsFixed(6)}, '
                      '${data.longitude!.toStringAsFixed(6)}'
                : '—',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHours() {
    return _SectionWithEdit(
      titleKey: 'working_hours',
      onEdit: () => onEditStep(3),
      child: Column(
        children: data.workingDays
            .map(
              (day) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: LocalizedLabel(
                        text: day.key,
                        style: TextStyles.darkRegular14,
                      ),
                    ),
                    // الساعات ممكن تكون null لو اليوم لسه متحددش
                    // فبنعرض شرطة بدل ما نعمل force unwrap
                    day.isClosed
                        ? LocalizedLabel(
                            text: 'closed',
                            style: TextStyles.darkBold12.copyWith(
                              color: AppColors.redColor,
                            ),
                          )
                        : Label(
                            text:
                                '${day.openTime?.toLocalizedString() ?? '--:--'}'
                                ' - '
                                '${day.closeTime?.toLocalizedString() ?? '--:--'}',
                            style: TextStyles.darkBold12,
                          ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// كارت مراجعة بعنوان وزرار تعديل على اليمين
class _SectionWithEdit extends StatelessWidget {
  final String titleKey;
  final VoidCallback onEdit;
  final Widget child;

  const _SectionWithEdit({
    required this.titleKey,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: LocalizedLabel(
                  text: titleKey,
                  style: TextStyles.blackBold16,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16.sp,
                      color: AppColors.primaryColor,
                    ),
                    Gap(4.w),
                    LocalizedLabel(
                      text: 'edit',
                      style: TextStyles.darkBold12.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(12.h),
          child,
        ],
      ),
    );
  }
}
