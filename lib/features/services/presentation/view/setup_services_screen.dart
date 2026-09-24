import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/auth/register/data/services_catalog.dart';
import 'package:lavanderia_partner/features/services/data/models/selected_service.dart';

/// شاشة إعداد الخدمات، بتظهر مرة واحدة بعد أول تسجيل دخول
/// اليوزر بيختار الخدمات ويحدد سعر لكل واحدة، وبعد الحفظ مبتظهرش تاني
class SetupServicesScreen extends StatefulWidget {
  const SetupServicesScreen({super.key});

  @override
  State<SetupServicesScreen> createState() => _SetupServicesScreenState();
}

class _SetupServicesScreenState extends State<SetupServicesScreen> {
  /// الخدمات المختارة بالـ id عشان الوصول يبقى سريع
  final Map<String, SelectedService> _selected = {};

  /// كنترولر لكل حقل سعر، بيتعمل وقت الاختيار وبيتمسح وقت الإلغاء
  final Map<String, TextEditingController> _priceControllers = {};

  /// الخدمات اللي اتختارت ومحطّتش سعر، بتتعلّم بالأحمر بعد محاولة الحفظ
  Set<String> _invalidPrices = {};

  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// بينقل الأسعار من الكنترولرز للموديل وبيرجّع الخدمات مرتبة حسب الكتالوج
  List<SelectedService> _collectSelection() {
    for (final entry in _selected.entries) {
      entry.value.price = _priceControllers[entry.key]?.text.trim() ?? '';
    }
    return ServicesCatalog.all
        .where((option) => _selected.containsKey(option.id))
        .map((option) => _selected[option.id]!)
        .toList();
  }

  void _toggleService(ServiceOption option) {
    setState(() {
      if (_selected.containsKey(option.id)) {
        _selected.remove(option.id);
        _priceControllers.remove(option.id)?.dispose();
        _invalidPrices.remove(option.id);
        return;
      }

      _selected[option.id] = SelectedService(
        id: option.id,
        name: option.labelKey.tr(),
        emoji: option.emoji,
      );
      _priceControllers[option.id] = TextEditingController();
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_selected.isEmpty) {
      _showMessage('select_at_least_one_service');
      return;
    }

    // بنحدّث الأسعار من الكنترولرز قبل التحقق
    final services = _collectSelection();

    final missing = services
        .where((service) => !service.hasValidPrice)
        .map((service) => service.id)
        .toSet();

    if (missing.isNotEmpty) {
      setState(() => _invalidPrices = missing);
      _showMessage('enter_price_for_all_services');
      return;
    }

    setState(() {
      _invalidPrices = {};
      _isSaving = true;
    });

    // TODO: ربط الـ API — services.map((s) => s.toJson()).toList()
    // العلامة بتتحفظ بعد نجاح الإرسال بس، عشان لو فشل الشاشة تظهر تاني
    await CacheManager.setServicesSetupCompleted();

    if (!mounted) return;
    context.go(AppRouter.initialRoot);
  }

  void _showMessage(String messageKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Label(text: messageKey.tr(), style: TextStyles.whiteBold14),
        backgroundColor: AppColors.redColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 30.h),
              children: [
                LocalizedLabel(
                  text: 'choose_your_services',
                  textAlign: TextAlign.center,
                  style: TextStyles.darkRegular16.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
                Gap(16.h),

                ...ServicesCatalog.all.map(_buildServiceTile),

                Gap(20.h),
                CustomButton(
                  onPressed: _submit,
                  title: _selected.isEmpty
                      ? 'save'.tr()
                      : 'save_with_count'.tr(
                          namedArgs: {'count': '${_selected.length}'},
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// نفس الهيدر الأزرق بتاع التسجيل عشان الشاشة تبان تكملة للـ flow
  /// من غير زرار رجوع لأن الإعداد لازم يخلص قبل الدخول للرئيسية
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.primaryColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        bottom: 18.h,
        left: 16.w,
        right: 16.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedLabel(
            text: 'setup_services_title',
            style: TextStyles.whiteBold15.copyWith(fontSize: 18.sp),
          ),
          Gap(4.h),
          LocalizedLabel(
            text: 'setup_services_subtitle',
            maxLines: 2,
            style: TextStyles.whiteBold14.copyWith(
              fontWeight: FontWeight.w300,
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(ServiceOption option) {
    final isSelected = _selected.containsKey(option.id);
    final hasError = _invalidPrices.contains(option.id);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: hasError
                ? AppColors.redColor
                : isSelected
                ? AppColors.primaryColor
                : Colors.grey.withValues(alpha: 0.25),
            width: isSelected || hasError ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          children: [
            _buildServiceHeader(option, isSelected),
            // حقل السعر بيظهر تحت الخدمة المختارة بس
            if (isSelected) _buildPriceField(option, hasError),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeader(ServiceOption option, bool isSelected) {
    return InkWell(
      onTap: () => _toggleService(option),
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Label(text: option.emoji, style: TextStyle(fontSize: 20.sp)),
            Gap(10.w),
            Expanded(
              child: LocalizedLabel(
                text: option.labelKey,
                style: isSelected
                    ? TextStyles.blackBold16.copyWith(
                        color: AppColors.primaryColor,
                      )
                    : TextStyles.darkRegular16,
              ),
            ),
            _buildCheckMark(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckMark(bool isSelected) {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : AppColors.greyColor4,
          width: 1.4,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, size: 15.sp, color: AppColors.whiteColor)
          : null,
    );
  }

  Widget _buildPriceField(ServiceOption option, bool hasError) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
          Gap(12.h),
          Row(
            children: [
              LocalizedLabel(
                text: 'service_price',
                style: TextStyles.darkBold14,
              ),
              Gap(12.w),
              Expanded(
                child: SizedBox(
                  height: 44.h,
                  child: TextField(
                    controller: _priceControllers[option.id],
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
                    onChanged: (value) {
                      // بنشيل علامة الخطأ أول ما اليوزر يبدأ يكتب
                      if (!hasError) return;
                      setState(() => _invalidPrices.remove(option.id));
                    },
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
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        borderSide: BorderSide(
                          color: hasError ? AppColors.redColor : Colors.grey,
                          width: hasError ? 1.2 : 0.5,
                        ),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
