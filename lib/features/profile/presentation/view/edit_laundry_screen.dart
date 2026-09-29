import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/helpers/validators.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_phone_field.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/city_model.dart';
import 'package:lavanderia_partner/features/auth/register/data/register_data_source.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/map_picker_screen.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/laundry_cover_picker.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/register_section_card.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_profile.dart';
import 'package:lavanderia_partner/features/profile/data/profile_data_source.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/location_picker_card.dart';

/// تعديل بيانات المغسلة، الحقول هنا هي اللي بيقبلها PUT api/laundry/profile بس
/// بيرجّع النسخة المعدلة لما الحفظ ينجح، و null لو اليوزر رجع من غير حفظ
class EditLaundryScreen extends StatefulWidget {
  final LaundryProfile profile;

  const EditLaundryScreen({super.key, required this.profile});

  @override
  State<EditLaundryScreen> createState() => _EditLaundryScreenState();
}

class _EditLaundryScreenState extends State<EditLaundryScreen> {
  /// المدن كلها في ليبيا، فبنحصر البحث على الخريطة فيها
  static const String _countryCode = 'LY';

  final _formKey = GlobalKey<FormState>();
  final RegisterDataSource _citiesSource = getIt<RegisterDataSource>();
  final ProfileDataSource _profileSource = getIt<ProfileDataSource>();

  /// بنشتغل على نسخة عشان لو اليوزر رجع من غير حفظ الأصل مايتغيرش
  late final LaundryProfile _draft = widget.profile.copy();

  late final TextEditingController _nameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  String _completePhone = '';
  String _localPhone = '';

  List<CityModel> _cities = [];
  CityModel? _selectedCity;
  bool _isLoadingCities = true;
  bool _citiesFailed = false;

  /// بتتحط بعد محاولة حفظ فاشلة عشان التحذيرات تظهر
  /// من غير ما تبان لليوزر من أول لحظة
  bool _showCityError = false;
  bool _showMapError = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _draft.name);
    _ownerNameController = TextEditingController(text: _draft.ownerName);
    _phoneController = TextEditingController(text: _draft.ownerPhoneLocal);
    _addressController = TextEditingController(text: _draft.address);
    _completePhone = _draft.ownerPhoneNumber;
    _localPhone = _draft.ownerPhoneLocal;
    _loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
      _citiesFailed = false;
    });

    final result = await _citiesSource.getCities();
    if (!mounted) return;

    result.fold(
      (_) => setState(() {
        _isLoadingCities = false;
        _citiesFailed = true;
      }),
      (cities) => setState(() {
        _cities = cities;
        _isLoadingCities = false;
        // بنرجّع المدينة المحفوظة في بيانات المغسلة
        _selectedCity = cities
            .where((city) => city.id == _draft.cityId)
            .firstOrNull;
      }),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLatitude: _draft.latitude,
          initialLongitude: _draft.longitude,
          countryCode: _countryCode,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _draft.latitude = result.latitude;
      _draft.longitude = result.longitude;
      // العنوان اللي رجع من الخريطة بيملى الحقل، واليوزر يقدر يعدله بعدها
      final picked = result.address.trim();
      if (picked.isNotEmpty) _addressController.text = picked;
      _showMapError = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final formValid = _formKey.currentState!.validate();
    final mapValid = _draft.hasLocationOnMap;
    // الدروب داون بره الـ Form فبنتحقق منه بإيدينا
    final cityValid = _selectedCity != null;

    // بنعرض كل الأخطاء مع بعض بدل ما اليوزر يصلح واحد ويكتشف التاني
    if (!mapValid || !cityValid) {
      setState(() {
        _showMapError = !mapValid;
        _showCityError = !cityValid;
      });
    }
    if (!formValid || !mapValid || !cityValid) return;

    // لو اليوزر ماغيّرش الرقم، onChanged مابيتنديش
    // فبنعتمد على اللي كان متخزن بدل ما نبعت رقم فاضي
    final typed = _phoneController.text.trim();
    if (typed != _localPhone) _localPhone = typed;

    _draft
      ..name = _nameController.text.trim()
      ..ownerName = _ownerNameController.text.trim()
      ..ownerPhoneNumber = _completePhone
      ..ownerPhoneLocal = _localPhone
      ..address = _addressController.text.trim()
      ..cityId = _selectedCity!.id;

    setState(() => _isSaving = true);
    final result = await _profileSource.updateProfile(_draft);
    if (!mounted) return;

    result.fold((failure) {
      setState(() => _isSaving = false);
      // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
      if (failure is ServerFailure || failure is UnknownFailure) {
        context.showErrorMessage(failure.message);
      }
    }, (_) => Navigator.of(context).pop(_draft));
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

  /// كارت بيانات المغسلة: الصورة والاسم والمسؤول ورقمه
  Widget _buildInfoCard() {
    return RegisterSectionCard(
      titleKey: 'laundry_info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الصورة اختيارية هنا، لأن المغسلة عندها صورة محفوظة أصلاً
          LaundryCoverPicker(
            image: _draft.image,
            imageUrl: _draft.imageUrl,
            onChanged: (file) => setState(() => _draft.image = file),
          ),
          Gap(16.h),

          Customtextfield(
            labelText: 'laundry_name',
            hintText: 'laundry_name_hint',
            textEditingController: _nameController,
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

          _FieldLabel(labelKey: 'owner_phone'),
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
    );
  }

  /// كارت الموقع: المدينة والعنوان وتحديد الدبوس على الخريطة
  Widget _buildLocationCard() {
    return RegisterSectionCard(
      titleKey: 'location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(labelKey: 'city'),
          Gap(8.h),
          _buildCityDropdown(),
          Gap(14.h),

          Customtextfield(
            labelText: 'address',
            hintText: 'address',
            textEditingController: _addressController,
            keyboardType: TextInputType.streetAddress,
            validator: Validators.validateEmpty,
          ),
          Gap(16.h),

          LocationPickerCard(
            latitude: _draft.latitude,
            longitude: _draft.longitude,
            address: _addressController.text,
            hasError: _showMapError,
            onTap: _openMapPicker,
          ),
        ],
      ),
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
