import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/helpers/validators.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_phone_field.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';
import 'package:lavanderia_partner/features/auth/register/data/locations_data_source.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/country_model.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/map_picker_screen.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/laundry_cover_picker.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/register_section_card.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_profile.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/location_picker_card.dart';

/// تعديل بيانات المغسلة
/// الموقع جوه الصفحة دي مش صفحة لوحدها، فاليوزر بيعدل كل حاجة في مكان واحد
/// بيرجّع النسخة المعدلة لما اليوزر يحفظ، و null لو رجع من غير حفظ
class EditLaundryScreen extends StatefulWidget {
  final LaundryProfile profile;

  const EditLaundryScreen({super.key, required this.profile});

  @override
  State<EditLaundryScreen> createState() => _EditLaundryScreenState();
}

class _EditLaundryScreenState extends State<EditLaundryScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationsDataSource _locationsSource = const StaticLocationsDataSource();

  /// بنشتغل على نسخة عشان لو اليوزر رجع من غير حفظ الأصل مايتغيرش
  late final LaundryProfile _draft = widget.profile.copy();

  late final TextEditingController _laundryNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _areaController;

  String _completePhone = '';
  String _localPhone = '';

  List<CountryModel> _countries = [];
  CountryModel? _selectedCountry;
  CityModel? _selectedCity;
  bool _isLoadingCountries = true;

  /// بتتحط بعد محاولة حفظ فاشلة عشان التحذيرات تظهر
  /// من غير ما تبان لليوزر من أول لحظة
  bool _showDropdownErrors = false;
  bool _showMapError = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _laundryNameController = TextEditingController(text: _draft.laundryName);
    _ownerNameController = TextEditingController(text: _draft.ownerName);
    _phoneController = TextEditingController(text: _draft.phoneLocal);
    _emailController = TextEditingController(text: _draft.email);
    _areaController = TextEditingController(text: _draft.areaName);
    _completePhone = _draft.phone;
    _localPhone = _draft.phoneLocal;
    _loadCountries();
  }

  @override
  void dispose() {
    _laundryNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final countries = await _locationsSource.getCountries();
    if (!mounted) return;

    setState(() {
      _countries = countries;
      _isLoadingCountries = false;
      _restoreSelection();
    });
  }

  /// بنرجّع الدولة والمدينة المحفوظين في بيانات المغسلة
  void _restoreSelection() {
    if (_draft.countryId == null) return;

    for (final country in _countries) {
      if (country.id != _draft.countryId) continue;
      _selectedCountry = country;

      for (final city in country.cities) {
        if (city.id == _draft.cityId) _selectedCity = city;
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
          initialLatitude: _draft.latitude,
          initialLongitude: _draft.longitude,
          countryCode: _selectedCountry?.isoCode,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _draft.latitude = result.latitude;
      _draft.longitude = result.longitude;
      _draft.pickedAddress = result.address;
      _showMapError = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final formValid = _formKey.currentState!.validate();
    final mapValid = _draft.hasLocationOnMap;
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

    // لو اليوزر ماغيّرش الرقم، onChanged مابيتنديش
    // فبنعتمد على اللي كان متخزن بدل ما نبعت رقم فاضي
    final typed = _phoneController.text.trim();
    if (typed != _localPhone) _localPhone = typed;

    _draft
      ..laundryName = _laundryNameController.text.trim()
      ..ownerName = _ownerNameController.text.trim()
      ..phone = _completePhone
      ..phoneLocal = _localPhone
      ..email = _emailController.text.trim()
      ..areaName = _areaController.text.trim()
      ..countryId = _selectedCountry!.id
      ..cityId = _selectedCity!.id;

    setState(() => _isSaving = true);
    // مؤقتاً تأخير بسيط بدل نداء الـ API
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      appBar: const CustomAppBar(title: 'edit_laundry_info'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              Gap(16.h),
              _buildLocationCard(),
              Gap(24.h),
              CustomButton(
                // بنقفل الضغط وقت الحفظ عشان مايتبعتش مرتين
                onPressed: _isSaving ? () {} : _save,
                title: _isSaving ? 'saving' : 'save_changes',
                backgroundColor: _isSaving
                    ? AppColors.primaryColor.withValues(alpha: 0.6)
                    : AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// كارت بيانات المغسلة: الصورة والاسم والمسؤول والتواصل
  Widget _buildInfoCard() {
    return RegisterSectionCard(
      titleKey: 'laundry_info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصورة اختيارية هنا، لأن المغسلة عندها صورة محفوظة أصلاً
          LaundryCoverPicker(
            image: _draft.coverImage,
            onChanged: (file) => setState(() => _draft.coverImage = file),
          ),
          Gap(16.h),

          Customtextfield(
            labelText: 'laundry_name',
            hintText: 'laundry_name_hint',
            textEditingController: _laundryNameController,
            keyboardType: TextInputType.text,
            validator: Validators.displayNameValidator,
          ),
          Gap(14.h),

          Customtextfield(
            labelText: 'owner_name',
            hintText: 'full_name',
            textEditingController: _ownerNameController,
            keyboardType: TextInputType.name,
            validator: Validators.displayNameValidator,
          ),
          Gap(14.h),

          _FieldLabel(labelKey: 'phone_number'),
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
          Gap(14.h),

          Customtextfield(
            labelText: 'email_optional',
            hintText: 'example@email.com',
            textEditingController: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: _optionalEmailValidator,
          ),
        ],
      ),
    );
  }

  /// كارت الموقع: الدولة والمدينة والمنطقة وتحديد الدبوس على الخريطة
  /// كان صفحة لوحده في الديزاين، وضمّيناه هنا عشان التعديل يبقى في مكان واحد
  Widget _buildLocationCard() {
    return RegisterSectionCard(
      titleKey: 'location',
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
          Gap(16.h),

          LocationPickerCard(
            latitude: _draft.latitude,
            longitude: _draft.longitude,
            address: _draft.pickedAddress,
            hasError: _showMapError,
            onTap: _openMapPicker,
          ),
        ],
      ),
    );
  }

  /// البريد اختياري: فاضي يعدي، ومكتوب لازم يبقى صحيح
  String? _optionalEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Validators.emailValidator(value);
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
          text: _selectedCountry == null
              ? 'select_country_first'
              : 'select_city',
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
}

/// الإطار الموحد للدروب داون عشان يبقى شبه باقي الحقول
class _DropdownShell extends StatelessWidget {
  final Widget child;
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

/// ليبل فوق الحقول اللي مش Customtextfield وبالتالي مالهاش labelText
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
