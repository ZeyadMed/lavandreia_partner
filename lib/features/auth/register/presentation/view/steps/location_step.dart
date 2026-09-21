import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/helpers/validators.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_phone_field.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';
import 'package:lavanderia_partner/features/auth/register/data/locations_data_source.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/country_model.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/map_picker_screen.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/register_section_card.dart';

/// الخطوة التانية: الدولة والمدينة والمنطقة ورقم المغسلة وتحديد الموقع
class LocationStep extends StatefulWidget {
  final RegisterData data;
  final VoidCallback onNext;

  const LocationStep({super.key, required this.data, required this.onNext});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final _formKey = GlobalKey<FormState>();
  final LocationsDataSource _locationsSource = const StaticLocationsDataSource();

  late final TextEditingController _areaController;
  late final TextEditingController _phoneController;

  String _completePhone = '';

  /// الرقم من غير الكود، بيتخزن عشان ترجيع الحقل لو اليوزر رجع للخطوة
  String _localPhone = '';

  /// بيتحط بعد محاولة حفظ فاشلة عشان تحذير الدروب داون يظهر
  bool _showDropdownErrors = false;

  List<CountryModel> _countries = [];
  CountryModel? _selectedCountry;
  CityModel? _selectedCity;
  bool _isLoadingCountries = true;

  /// بيتحط بعد أول محاولة حفظ فاشلة عشان تحذير الخريطة يظهر
  /// من غير ما يبان لليوزر من أول لحظة
  bool _showMapError = false;

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController(text: widget.data.areaName);
    // الحقل بيترجّع بالرقم المحلي عشان اليوزر يلاقي رقمه لما يرجع للخطوة
    _phoneController = TextEditingController(text: widget.data.laundryPhoneLocal);
    _completePhone = widget.data.laundryPhone;
    _localPhone = widget.data.laundryPhoneLocal;
    _loadCountries();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final countries = await _locationsSource.getCountries();
    if (!mounted) return;

    setState(() {
      _countries = countries;
      _isLoadingCountries = false;
      // بنرجّع اللي اليوزر كان مختاره لو رجع خطوة لورا
      _restoreSelection();
    });
  }

  void _restoreSelection() {
    final data = widget.data;
    if (data.countryId == null) return;

    for (final country in _countries) {
      if (country.id != data.countryId) continue;
      _selectedCountry = country;

      for (final city in country.cities) {
        if (city.id == data.cityId) _selectedCity = city;
      }
      return;
    }
  }

  void _onCountryChanged(CountryModel? country) {
    setState(() {
      _selectedCountry = country;
      // المدينة القديمة مش بتنتمي للدولة الجديدة فلازم تتصفّر
      _selectedCity = null;
      _clearDropdownErrorIfResolved();
    });
  }

  /// بيخفي تحذير الدروب داون أول ما الاتنين يتحددوا
  void _clearDropdownErrorIfResolved() {
    if (!_showDropdownErrors) return;
    if (_selectedCountry != null && _selectedCity != null) {
      _showDropdownErrors = false;
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLatitude: widget.data.latitude,
          initialLongitude: widget.data.longitude,
          countryCode: _selectedCountry?.isoCode,
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
    final formValid = _formKey.currentState!.validate();
    final mapValid = widget.data.hasLocationOnMap;
    // الدروب داون بره الـ Form فبنتحقق منه بإيدينا
    final dropdownsValid = _selectedCountry != null && _selectedCity != null;

    // بنعرض كل الأخطاء مع بعض بدل ما اليوزر يصلح واحد ويكتشف التاني
    if (!mapValid || !dropdownsValid) {
      setState(() {
        _showMapError = !mapValid;
        _showDropdownErrors = !dropdownsValid;
      });
    }
    if (!formValid || !mapValid || !dropdownsValid) return;

    // لو اليوزر رجع للخطوة وماغيّرش الرقم، onChanged مابيتنديش
    final typed = _phoneController.text.trim();
    if (typed != _localPhone) _localPhone = typed;

    final data = widget.data;
    data.countryId = _selectedCountry!.id;
    data.countryName = _selectedCountry!.nameFor(context.locale.languageCode);
    data.cityId = _selectedCity!.id;
    data.cityName = _selectedCity!.nameFor(context.locale.languageCode);
    data.areaName = _areaController.text.trim();
    data.laundryPhone = _completePhone;
    data.laundryPhoneLocal = _localPhone;

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegisterSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel(labelKey: 'country'),
                Gap(8.h),
                _buildCountryDropdown(),
                Gap(14.h),

                _FieldLabel(labelKey: 'city'),
                Gap(8.h),
                _buildCityDropdown(),
                Gap(14.h),

                Customtextfield(
                  labelText: 'area_name',
                  hintText: 'area_name_hint',
                  textEditingController: _areaController,
                  keyboardType: TextInputType.text,
                  validator: Validators.validateEmpty,
                ),
                Gap(14.h),

                _FieldLabel(labelKey: 'laundry_phone'),
                Gap(8.h),
                CustomPhoneField(
                  controller: _phoneController,
                  onChanged: (phone) {
                    _completePhone = phone.completeNumber;
                    _localPhone = phone.number;
                  },
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'phoneNumberEmpty'.tr()
                      : null,
                ),
              ],
            ),
          ),
          Gap(16.h),

          _buildMapCard(),
          Gap(20.h),

          CustomButton(onPressed: _submit, title: 'next'.tr()),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    if (_isLoadingCountries) return const _DropdownPlaceholder();

    return _DropdownShell(
      hasError: _showDropdownErrors && _selectedCountry == null,
      child: DropdownButton<CountryModel>(
        isExpanded: true,
        value: _selectedCountry,
        hint: LocalizedLabel(
          text: 'select_country',
          style: TextStyles.darkRegular16.copyWith(color: AppColors.greyColor3),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        items: _countries
            .map(
              (country) => DropdownMenuItem(
                value: country,
                child: Label(
                  text: country.nameFor(context.locale.languageCode),
                  style: TextStyles.darkRegular16,
                ),
              ),
            )
            .toList(),
        onChanged: _onCountryChanged,
      ),
    );
  }

  Widget _buildCityDropdown() {
    final cities = _selectedCountry?.cities ?? const <CityModel>[];

    return _DropdownShell(
      hasError: _showDropdownErrors && _selectedCity == null,
      child: DropdownButton<CityModel>(
        isExpanded: true,
        value: _selectedCity,
        hint: LocalizedLabel(
          // الهينت بيوضح إن لازم الدولة الأول
          text: _selectedCountry == null ? 'select_country_first' : 'select_city',
          style: TextStyles.darkRegular16.copyWith(color: AppColors.greyColor3),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        items: cities
            .map(
              (city) => DropdownMenuItem(
                value: city,
                child: Label(
                  text: city.nameFor(context.locale.languageCode),
                  style: TextStyles.darkRegular16,
                ),
              ),
            )
            .toList(),
        // مقفول لحد ما دولة تتحدد
        onChanged: cities.isEmpty
            ? null
            : (city) => setState(() {
                _selectedCity = city;
                _clearDropdownErrorIfResolved();
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

/// بيتعرض وقت تحميل الدول عشان الشكل مايقفزش لما اللستة توصل
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
