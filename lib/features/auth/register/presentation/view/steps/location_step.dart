import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/city_model.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/auth/register/data/register_data_source.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/map_picker_screen.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/register_section_card.dart';

/// الخطوة التانية: المدينة وتحديد الموقع على الخريطة
class LocationStep extends StatefulWidget {
  final RegisterData data;
  final VoidCallback onNext;

  const LocationStep({super.key, required this.data, required this.onNext});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  /// المدن كلها في ليبيا، فبنحصر البحث على الخريطة فيها
  static const String _countryCode = 'LY';

  final RegisterDataSource _dataSource = getIt<RegisterDataSource>();

  /// بيتحط بعد محاولة حفظ فاشلة عشان تحذير الدروب داون يظهر
  bool _showCityError = false;

  List<CityModel> _cities = [];
  CityModel? _selectedCity;
  bool _isLoadingCities = true;
  bool _citiesFailed = false;

  /// بيتحط بعد أول محاولة حفظ فاشلة عشان تحذير الخريطة يظهر
  /// من غير ما يبان لليوزر من أول لحظة
  bool _showMapError = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
      _citiesFailed = false;
    });

    final result = await _dataSource.getCities();
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        _isLoadingCities = false;
        _citiesFailed = true;
      }),
      (cities) => setState(() {
        _cities = cities;
        _isLoadingCities = false;
        // بنرجّع اللي اليوزر كان مختاره لو رجع خطوة لورا
        _selectedCity = cities
            .where((city) => city.id == widget.data.cityId)
            .firstOrNull;
      }),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLatitude: widget.data.latitude,
          initialLongitude: widget.data.longitude,
          countryCode: _countryCode,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      widget.data.latitude = result.latitude;
      widget.data.longitude = result.longitude;
      widget.data.pickedAddress = result.address;
      _showMapError = false;
    });
  }

  void _submit() {
    final mapValid = widget.data.hasLocationOnMap;
    final cityValid = _selectedCity != null;

    // بنعرض كل الأخطاء مع بعض بدل ما اليوزر يصلح واحد ويكتشف التاني
    if (!mapValid || !cityValid) {
      setState(() {
        _showMapError = !mapValid;
        _showCityError = !cityValid;
      });
      return;
    }

    final data = widget.data;
    data.cityId = _selectedCity!.id;
    data.cityName = _selectedCity!.name;

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegisterSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldLabel(labelKey: 'city'),
              Gap(8.h),
              _buildCityDropdown(),
            ],
          ),
        ),
        Gap(16.h),

        _buildMapCard(),
        Gap(20.h),

        CustomButton(onPressed: _submit, title: 'next'.tr()),
      ],
    );
  }

  Widget _buildCityDropdown() {
    if (_isLoadingCities) return const _DropdownPlaceholder();

    if (_citiesFailed) {
      return _DropdownShell(
        child: InkWell(
          onTap: _loadCities,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              children: [
                Expanded(
                  child: LocalizedLabel(
                    text: 'cities_load_failed',
                    style: TextStyles.darkRegular16.copyWith(
                      color: AppColors.redColor,
                    ),
                  ),
                ),
                const Icon(Icons.refresh, color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      );
    }

    return _DropdownShell(
      hasError: _showCityError && _selectedCity == null,
      child: DropdownButton<CityModel>(
        isExpanded: true,
        value: _selectedCity,
        hint: LocalizedLabel(
          text: 'select_city',
          style: TextStyles.darkRegular16.copyWith(color: AppColors.greyColor3),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        items: _cities
            .map(
              (city) => DropdownMenuItem(
                value: city,
                child: Label(text: city.name, style: TextStyles.darkRegular16),
              ),
            )
            .toList(),
        onChanged: (city) => setState(() {
          _selectedCity = city;
          _showCityError = false;
        }),
      ),
    );
  }

  /// كارت الخريطة: بيعرض دعوة للتحديد، وبعد الاختيار بيعرض العنوان والإحداثيات
  Widget _buildMapCard() {
    final data = widget.data;
    final hasLocation = data.hasLocationOnMap;

    return GestureDetector(
      onTap: _openMapPicker,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _showMapError
                ? AppColors.redColor
                : hasLocation
                ? AppColors.primaryColor
                : Colors.grey.withValues(alpha: 0.25),
            width: _showMapError || hasLocation ? 1.2 : 0.8,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasLocation ? Icons.location_on : Icons.add_location_alt_outlined,
              size: 34.sp,
              color: hasLocation
                  ? AppColors.primaryColor
                  : AppColors.greyColor3,
            ),
            Gap(10.h),
            LocalizedLabel(
              text: hasLocation ? 'location_selected' : 'pick_location_on_map',
              textAlign: TextAlign.center,
              style: TextStyles.blackBold16,
            ),
            Gap(6.h),
            Label(
              text: hasLocation
                  ? (data.pickedAddress?.isNotEmpty == true
                        ? data.pickedAddress!
                        : '${data.latitude!.toStringAsFixed(6)}, '
                              '${data.longitude!.toStringAsFixed(6)}')
                  : 'pick_location_hint'.tr(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.greyColor3,
              ),
            ),
            if (hasLocation) ...[
              Gap(10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Label(
                  text:
                      '${data.latitude!.toStringAsFixed(6)}, '
                      '${data.longitude!.toStringAsFixed(6)}',
                  style: TextStyles.darkBold12,
                ),
              ),
              Gap(8.h),
              LocalizedLabel(
                text: 'tap_to_change_location',
                style: TextStyles.darkRegular12.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ],
            if (_showMapError) ...[
              Gap(10.h),
              LocalizedLabel(
                text: 'location_required',
                textAlign: TextAlign.center,
                style: TextStyles.darkBold12.copyWith(color: AppColors.redColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// الإطار الموحد للدروب داون عشان يبقى شبه باقي الحقول
class _DropdownShell extends StatelessWidget {
  final Widget child;

  /// بيلوّن الإطار بالأحمر لما اليوزر يحاول يكمل من غير اختيار
  final bool hasError;

  const _DropdownShell({required this.child, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: hasError ? AppColors.redColor : Colors.grey,
              width: hasError ? 1.2 : 0.5,
            ),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
        if (hasError) ...[
          Gap(6.h),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: LocalizedLabel(
              text: 'fieldEmpty',
              style: TextStyles.darkBold12.copyWith(color: AppColors.redColor),
            ),
          ),
        ],
      ],
    );
  }
}

/// بيتعرض وقت تحميل المدن عشان الشكل مايقفزش لما اللستة توصل
class _DropdownPlaceholder extends StatelessWidget {
  const _DropdownPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      alignment: AlignmentDirectional.centerStart,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        border: const Border.fromBorderSide(
          BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: SizedBox(
        width: 18.w,
        height: 18.w,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String labelKey;

  const _FieldLabel({required this.labelKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: LocalizedLabel(text: labelKey, style: TextStyles.blackBold16),
      ),
    );
  }
}
