import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/core/widget/custom_phone_field.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/accredited_drivers_data_source.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accredited_driver.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view_model/accredited_drivers_cubits.dart';

/// بوتوم شيت اعتماد دليفري برقم موبايله
/// بيرجّع الدليفري اللي اتعتمد، أو null لو اتقفل من غير اعتماد
Future<AccreditedDriver?> showAccreditDriverSheet(BuildContext context) {
  return showModalBottomSheet<AccreditedDriver>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => AccreditDriverCubit(getIt<AccreditedDriversDataSource>()),
      child: const _AccreditDriverSheet(),
    ),
  );
}

class _AccreditDriverSheet extends StatefulWidget {
  const _AccreditDriverSheet();

  @override
  State<_AccreditDriverSheet> createState() => _AccreditDriverSheetState();
}

class _AccreditDriverSheetState extends State<_AccreditDriverSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  /// الرقم بالكود +218، والسيرفر بيقبل أي صيغة ليبية
  String _completePhone = '';

  /// رسالة السيرفر لو الاعتماد فشل، بتظهر جوه الشيت لأن الـ snackbar
  /// بيستخبى وراه، وبتتمسح أول ما اليوزر يعدّل الرقم
  String? _serverError;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AccreditDriverCubit>().submit(_completePhone);
  }

  void _onStateChanged(BuildContext context, BaseState<AccreditedDriver> state) {
    if (state.isSuccess && state.data != null) {
      Navigator.of(context).pop(state.data);
      return;
    }
    // انتهاء الجلسة بيرجّع للوجين لوحده فمالوش رسالة هنا
    if (state.isFailure && state.failure is! UnauthorizedFailure) {
      setState(() => _serverError = state.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccreditDriverCubit, BaseState<AccreditedDriver>>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStateChanged,
      child: Padding(
        // عشان الشيت يطلع فوق الكيبورد
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
          child: Form(
            key: _formKey,
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
                  text: 'accredit_driver',
                  textAlign: TextAlign.center,
                  style: TextStyles.boldStyle(18, weight: FontWeight.w800),
                ),
                Gap(6.h),
                LocalizedLabel(
                  text: 'accredit_driver_hint',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyles.darkRegular14.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
                Gap(20.h),
                CustomPhoneField(
                  controller: _phoneController,
                  onChanged: (phone) {
                    _completePhone = phone.completeNumber;
                    if (_serverError != null) {
                      setState(() => _serverError = null);
                    }
                  },
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'phoneNumberEmpty'.tr()
                      : null,
                ),
                if (_serverError != null) ...[
                  Gap(4.h),
                  Label(
                    text: _serverError!,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.redColor,
                    ),
                  ),
                ],
                Gap(18.h),
                BlocBuilder<AccreditDriverCubit, BaseState<AccreditedDriver>>(
                  builder: (context, state) => CustomButton(
                    // بنقفل الضغط وقت الإرسال عشان مايتبعتش مرتين
                    onPressed: state.isLoading ? () {} : _submit,
                    title: state.isLoading ? 'accrediting' : 'accredit',
                    backgroundColor: state.isLoading
                        ? AppColors.primaryColor.withValues(alpha: 0.6)
                        : AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
