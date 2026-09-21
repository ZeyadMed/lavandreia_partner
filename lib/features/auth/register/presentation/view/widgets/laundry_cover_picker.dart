import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/helpers/image_picker_helper.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// اختيار صورة غلاف المغسلة في أول خطوة من التسجيل
/// فاضية بتبان كمساحة منقطة بدعوة للرفع، وبعد الاختيار بتعرض الصورة
/// ومعاها زرارين: تغيير وحذف
class LaundryCoverPicker extends StatelessWidget {
  /// الصورة المختارة، null يعني لسه مفيش صورة
  /// الصورة إجبارية، والتحقق منها بيحصل في الخطوة لأنها بره الـ Form
  final File? image;

  /// بيتنادى بالصورة الجديدة، أو بـ null لما اليوزر يمسحها
  final ValueChanged<File?> onChanged;

  /// بيتحط بعد محاولة حفظ فاشلة عشان التحذير يظهر
  /// من غير ما يبان لليوزر من أول لحظة
  final bool hasError;

  const LaundryCoverPicker({
    super.key,
    required this.image,
    required this.onChanged,
    this.hasError = false,
  });

  void _pick(BuildContext context) {
    ImagePickerHelper.showImagePicker(context, (file) {
      // الهيلبر بينده بـ null لو حصل error، فبنتجاهل ده
      // عشان مانمسحش صورة اليوزر القديمة من غير ما يطلب
      if (file != null) onChanged(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: LocalizedLabel(
              text: 'laundry_cover',
              style: TextStyles.blackBold16,
            ),
          ),
        ),
        Gap(8.h),
        image == null ? _buildEmpty(context) : _buildPreview(context),
        if (hasError) ...[
          Gap(6.h),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: LocalizedLabel(
              text: 'laundry_cover_required',
              style: TextStyles.darkBold12.copyWith(color: AppColors.redColor),
            ),
          ),
        ],
      ],
    );
  }

  /// الحالة الفاضية: إطار منقط فيه أيقونة ودعوة للرفع
  Widget _buildEmpty(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 150.h,
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasError
                ? AppColors.redColor
                : AppColors.primaryColor.withValues(alpha: 0.35),
            width: hasError ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 24.sp,
                color: AppColors.primaryColor,
              ),
            ),
            Gap(10.h),
            LocalizedLabel(
              text: 'add_laundry_cover',
              style: TextStyles.darkBold14.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            Gap(4.h),
            LocalizedLabel(
              text: 'laundry_cover_hint',
              textAlign: TextAlign.center,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.greyColor3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بعد الاختيار: الصورة كاملة ومعاها زرار تغيير وزرار حذف
  Widget _buildPreview(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Image.file(
            image!,
            height: 150.h,
            width: double.infinity,
            fit: BoxFit.cover,
            // لو الملف اتمسح من الجهاز بعد الاختيار
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150.h,
              color: AppColors.secondaryColor,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                size: 28.sp,
                color: AppColors.greyColor3,
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 8.h,
          end: 8.w,
          child: Row(
            children: [
              _CircleAction(
                icon: Icons.edit_outlined,
                onTap: () => _pick(context),
              ),
              Gap(6.w),
              _CircleAction(
                icon: Icons.delete_outline,
                color: AppColors.redColor,
                onTap: () => onChanged(null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// زرار دائري صغير بيتحط فوق الصورة
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleAction({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 17.sp,
          color: color ?? AppColors.primaryColor,
        ),
      ),
    );
  }
}
