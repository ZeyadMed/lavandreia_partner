import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/services/data/laundry_services_data_source.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/services_skeleton.dart';
import 'package:lavanderia_partner/features/services/presentation/view_model/services_cubits.dart';

/// كارت خدمة بيتفتح على أصنافها وجنب كل صنف حقل سعر
/// الأصناف بتتجاب أول مرة الكارت يتفتح بس، مش مع لستة الخدمات
/// مستخدم في صفحة الإعداد وصفحة إضافة خدمات
class ServicePriceTile extends StatefulWidget {
  final ServiceCategory service;
  final TextEditingController Function(int itemId) controllerFor;

  /// أصناف موجودة عند المغسلة أصلاً، بتظهر من غير حقل سعر
  final Set<int> addedItemIds;

  const ServicePriceTile({
    super.key,
    required this.service,
    required this.controllerFor,
    this.addedItemIds = const {},
  });

  @override
  State<ServicePriceTile> createState() => _ServicePriceTileState();
}

class _ServicePriceTileState extends State<ServicePriceTile> {
  /// بيتعمل أول ما الكارت يتفتح، وبيفضل عايش عشان مايجيبش الأصناف تاني
  ServiceItemsCubit? _itemsCubit;
  bool _isExpanded = false;

  @override
  void dispose() {
    _itemsCubit?.close();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      _itemsCubit ??= ServiceItemsCubit(
        dataSource: getIt<LaundryServicesDataSource>(),
        serviceId: widget.service.id,
      )..fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        decoration: BoxDecoration(
          color: _isExpanded ? AppColors.secondaryColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _isExpanded
                ? AppColors.primaryColor
                : Colors.grey.withValues(alpha: 0.25),
            width: _isExpanded ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (_isExpanded)
              BlocProvider.value(value: _itemsCubit!, child: _buildItems()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Label(
              text: widget.service.icon,
              style: TextStyle(fontSize: 20.sp),
            ),
            Gap(10.w),
            Expanded(
              child: Label(
                text: widget.service.name,
                style: _isExpanded
                    ? TextStyles.blackBold16.copyWith(
                        color: AppColors.primaryColor,
                      )
                    : TextStyles.darkRegular16,
              ),
            ),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: _isExpanded ? AppColors.primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItems() {
    return BlocBuilder<ServiceItemsCubit, BaseState<ServiceItem>>(
      builder: (context, state) {
        final Widget content;
        if (state.isFailure) {
          content = ServicesRetryMessage(
            messageKey: 'items_load_failed',
            onRetry: context.read<ServiceItemsCubit>().fetchData,
          );
        } else if (!state.isSuccess) {
          content = const ServiceItemsSkeleton();
        } else if (state.isEmpty) {
          content = Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: LocalizedLabel(
              text: 'no_service_items',
              textAlign: TextAlign.center,
              style: TextStyles.darkRegular14,
            ),
          );
        } else {
          content = Column(
            children: state.items
                .map(
                  (item) => widget.addedItemIds.contains(item.id)
                      ? _AddedItemRow(item: item)
                      : _ItemPriceRow(
                          item: item,
                          controller: widget.controllerFor(item.id),
                        ),
                )
                .toList(),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 6.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
              Gap(4.h),
              content,
            ],
          ),
        );
      },
    );
  }
}

/// صف صنف واحد: الاسم وحقل السعر
class _ItemPriceRow extends StatelessWidget {
  final ServiceItem item;
  final TextEditingController controller;

  const _ItemPriceRow({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Label(text: item.name, style: TextStyles.darkBold14),
          ),
          Gap(12.w),
          SizedBox(
            width: 120.w,
            height: 44.h,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // أرقام إنجليزي وفاصلة عشرية واحدة بحد أقصى رقمين بعدها
              // الـ $ مهم عشان التحقق يبقى على القيمة كلها مش على جزء منها
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)
                      ? newValue
                      : oldValue,
                ),
              ],
              textAlign: TextAlign.center,
              style: TextStyles.darkBold16,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyles.greyColor2Regular14,
                filled: true,
                fillColor: AppColors.whiteColor,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                suffixText: 'currency'.tr(),
                suffixStyle: TextStyles.darkBold12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// صنف المغسلة بتقدمه أصلاً، بيتعرض باهت وجنبه علامة "مضاف" بدل حقل السعر
class _AddedItemRow extends StatelessWidget {
  final ServiceItem item;

  const _AddedItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: SizedBox(
        height: 44.h,
        child: Row(
          children: [
            Expanded(
              child: Label(
                text: item.name,
                style: TextStyles.darkBold14.copyWith(
                  color: AppColors.greyColor3,
                ),
              ),
            ),
            Gap(12.w),
            Icon(
              Icons.check_circle_rounded,
              size: 18.sp,
              color: AppColors.primaryColor,
            ),
            Gap(4.w),
            LocalizedLabel(
              text: 'service_item_added',
              style: TextStyles.boldStyle(
                13,
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

/// رسالة فشل تحميل بزرار إعادة المحاولة
class ServicesRetryMessage extends StatelessWidget {
  final String messageKey;
  final VoidCallback onRetry;

  const ServicesRetryMessage({
    super.key,
    required this.messageKey,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalizedLabel(
              text: messageKey,
              textAlign: TextAlign.center,
              style: TextStyles.darkRegular14.copyWith(
                color: AppColors.redColor,
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
              label: LocalizedLabel(
                text: 'try_again',
                style: TextStyles.darkBold14.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
