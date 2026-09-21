import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/helpers/validators.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_phone_field.dart';
import 'package:lavanderia_partner/core/widget/custom_text_field.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/laundry_cover_picker.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/register_section_card.dart';

/// الخطوة الأولى: اسم المغسلة والمسؤول والتواصل وكلمة المرور
class LaundryInfoStep extends StatefulWidget {
  final RegisterData data;

  /// بيتنادى بعد ما الفاليديشن يعدي والبيانات تتحفظ في [data]
  final VoidCallback onNext;

  const LaundryInfoStep({super.key, required this.data, required this.onNext});

  @override
  State<LaundryInfoStep> createState() => _LaundryInfoStepState();
}

class _LaundryInfoStepState extends State<LaundryInfoStep> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _laundryNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  /// الرقم كامل بكود الدولة، بيتحدث من onChanged بتاع الحقل
  String _completePhone = '';

  /// الرقم من غير الكود، بيتخزن عشان ترجيع الحقل لو اليوزر رجع للخطوة
  String _localPhone = '';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  /// بيتحط بعد أول محاولة حفظ من غير صورة، عشان التحذير مايظهرش
  /// لليوزر قبل ما يحاول يكمل
  bool _showCoverError = false;

  @override
  void initState() {
    super.initState();
    // الكنترولرز بتتملّي من الداتا عشان لما اليوزر يرجع خطوة يلاقي كلامه
    final data = widget.data;
    _laundryNameController = TextEditingController(text: data.laundryName);
    _ownerNameController = TextEditingController(text: data.ownerName);
    // الحقل بيترجّع بالرقم المحلي عشان اليوزر يلاقي رقمه لما يرجع للخطوة
    _phoneController = TextEditingController(text: data.ownerPhoneLocal);
    _emailController = TextEditingController(text: data.email);
    _passwordController = TextEditingController(text: data.password);
    _confirmPasswordController = TextEditingController(text: data.password);
    _completePhone = data.ownerPhone;
    _localPhone = data.ownerPhoneLocal;
  }

  @override
  void dispose() {
    _laundryNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// البريد اختياري: فاضي يعدي، ومكتوب لازم يبقى صحيح
  String? _optionalEmailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Validators.emailValidator(value);
  }

  void _submit() {
    final formValid = _formKey.currentState!.validate();
    // الصورة بره الـ Form فبنتحقق منها بإيدينا
    final coverValid = widget.data.coverImage != null;

    // بنعرض الخطأين مع بعض بدل ما اليوزر يصلح واحد ويكتشف التاني
    if (!coverValid) setState(() => _showCoverError = true);
    if (!formValid || !coverValid) return;

    // لو اليوزر رجع للخطوة وماغيّرش الرقم، onChanged مابيتنديش
    // فبنعتمد على اللي كان متخزن بدل ما نبعت رقم فاضي
    final typed = _phoneController.text.trim();
    if (typed != _localPhone) _localPhone = typed;

    final data = widget.data;
    data.laundryName = _laundryNameController.text.trim();
    data.ownerName = _ownerNameController.text.trim();
    data.ownerPhone = _completePhone;
    data.ownerPhoneLocal = _localPhone;
    data.email = _emailController.text.trim();
    data.password = _passwordController.text;

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
                // صورة الغلاف أول حاجة في الصفحة، قبل اسم المغسلة
                LaundryCoverPicker(
                  image: widget.data.coverImage,
                  hasError: _showCoverError,
                  onChanged: (file) => setState(() {
                    widget.data.coverImage = file;
                    // التحذير بيختفي أول ما صورة تتحط، وبيرجع لو اتمسحت
                    _showCoverError = _showCoverError && file == null;
                  }),
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
                  // اختياري، والليبل بيوضح كده لليوزر
                  labelText: 'email_optional',
                  hintText: 'example@email.com',
                  textEditingController: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _optionalEmailValidator,
                ),
                Gap(14.h),

                Customtextfield(
                  labelText: 'password',
                  hintText: 'password_hint',
                  textEditingController: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscurePassword,
                  validator: Validators.passwordValidator,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                Gap(14.h),

                Customtextfield(
                  labelText: 'confirm_password',
                  hintText: 'confirm_password_hint',
                  textEditingController: _confirmPasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) => Validators.repeatPasswordValidator(
                    value: value,
                    Password: _passwordController.text,
                  ),
                  suffix: IconButton(
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                Gap(22.h),

                CustomButton(onPressed: _submit, title: 'next'.tr()),
              ],
            ),
          ),
        ],
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
