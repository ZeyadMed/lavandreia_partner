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
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_partner/features/trips/presentation/view_model/trips_cubits.dart';

/// بوتوم شيت إدخال الكود اللي الدليفري بيوريه للمغسلة،
/// في الاستلام وهو جايب الهدوم وفي التسليم وهو واخدها
/// بيرجّع true لو الكود اتأكد، أو null لو اتقفل من غير تأكيد
Future<bool?> showTripOtpSheet({
  required BuildContext context,
  required DeliveryTrip trip,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TripOtpSheet(trip: trip),
  );
}

class _TripOtpSheet extends StatefulWidget {
  final DeliveryTrip trip;

  const _TripOtpSheet({required this.trip});

  @override
  State<_TripOtpSheet> createState() => _TripOtpSheetState();
}

class _TripOtpSheetState extends State<_TripOtpSheet> {
  final TextEditingController _controller = TextEditingController();

  late final ConfirmTripOtpCubit _cubit = ConfirmTripOtpCubit(
    getIt<TripsDataSource>(),
    widget.trip,
  );

  bool get _isPickup => widget.trip.type == DeliveryTripType.pickup;

  @override
  void dispose() {
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    _cubit.confirm(code);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfirmTripOtpCubit, BaseState<void>>(
      bloc: _cubit,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.isSuccess) Navigator.of(context).pop(true);
      },
      builder: (context, state) => Padding(
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
                text: _isPickup
                    ? 'confirm_pickup_title'
                    : 'confirm_handover_title',
                textAlign: TextAlign.center,
                style: TextStyles.boldStyle(18, weight: FontWeight.w800),
              ),
              Gap(6.h),
              LocalizedLabel(
                text: _isPickup
                    ? 'confirm_pickup_hint'
                    : 'confirm_handover_hint',
                textAlign: TextAlign.center,
                style: TextStyles.darkRegular14.copyWith(
                  color: AppColors.greyColor3,
                ),
              ),
              Gap(20.h),
              _CodeField(
                controller: _controller,
                hasError: state.isFailure,
                onSubmitted: _submit,
              ),
              if (state.isFailure) ...[
                Gap(8.h),
                Label(
                  text: state.errorMessage ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.redColor,
                  ),
                ),
              ],
              Gap(22.h),
              _ConfirmButton(isLoading: state.isLoading, onTap: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;
  final VoidCallback onSubmitted;

  const _CodeField({
    required this.controller,
    required this.hasError,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      // طول الكود مش متحدد من السيرفر، فالحقل بيقبل لحد 8 أرقام
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      textAlign: TextAlign.center,
      style: TextStyles.boldStyle(
        24,
        weight: FontWeight.w700,
      ).copyWith(letterSpacing: 8),
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        hintText: '••••',
        hintStyle: TextStyles.greyColor2Regular14.copyWith(fontSize: 22),
        filled: true,
        fillColor: AppColors.filledColor,
        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: AppColors.semiWhiteColor2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: hasError ? AppColors.redColor : AppColors.semiWhiteColor2,
            width: hasError ? 1.2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(
            color: hasError ? AppColors.redColor : AppColors.primaryColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _ConfirmButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.whiteColor,
                ),
              )
            : LocalizedLabel(
                text: 'confirm',
                style: TextStyles.boldStyle(
                  16,
                  color: AppColors.whiteColor,
                  weight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
