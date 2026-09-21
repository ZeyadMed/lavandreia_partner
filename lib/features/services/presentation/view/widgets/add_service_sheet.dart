import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/auth/register/data/services_catalog.dart';

/// بوتوم شيت إضافة خدمة جديدة من الخدمات اللي المغسلة لسه مضافاهاش
/// بيرجّع الخدمة اللي اتختارت، أو null لو اتقفل من غير اختيار
/// السعر بيتحدد بعد كده من شيت التعديل
Future<ServiceOption?> showAddServiceSheet({
  required BuildContext context,
  required Set<String> existingIds,
}) {
  final available = ServicesCatalog.all
      .where((option) => !existingIds.contains(option.id))
      .toList();

  return showModalBottomSheet<ServiceOption>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AddServiceSheet(available: available),
  );
}

class _AddServiceSheet extends StatelessWidget {
  final List<ServiceOption> available;

  const _AddServiceSheet({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      // بنحدد أقصى ارتفاع عشان الليستة متملاش الشاشة كلها
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 20.h,
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
          LocalizedLabel(
            text: 'add_service',
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18, weight: FontWeight.w800),
          ),
          Gap(6.h),
          LocalizedLabel(
            text: available.isEmpty
                ? 'all_services_added'
                : 'add_service_hint',
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular12.copyWith(
              color: AppColors.greyColor4,
            ),
          ),
          Gap(18.h),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: available.length,
              separatorBuilder: (_, _) => Gap(8.h),
              itemBuilder: (context, index) => _AvailableServiceTile(
                option: available[index],
                onTap: () => Navigator.of(context).pop(available[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// خدمة متاحة للإضافة في الليستة
class _AvailableServiceTile extends StatelessWidget {
  final ServiceOption option;
  final VoidCallback onTap;

  const _AvailableServiceTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.semiWhiteColor2),
        ),
        child: Row(
          children: [
            Label(text: option.emoji, style: TextStyle(fontSize: 18.sp)),
            Gap(10.w),
            Expanded(
              child: LocalizedLabel(
                text: option.labelKey,
                maxLines: 1,
                style: TextStyles.boldStyle(14, weight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              size: 20.sp,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
