import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';

import 'dart:ui' as ui;

import 'package:lavanderia_partner/core/style/app_colors.dart';

class OtpTextField extends StatefulWidget {
  final TextEditingController pinController;
  const OtpTextField({super.key, required this.pinController});

  @override
  State<OtpTextField> createState() => _OtpTextFieldState();
}

class _OtpTextFieldState extends State<OtpTextField> {
  final formKey = GlobalKey<FormState>();

  final focusedBorderColor = Colors.black;
  final fillColor = const Color.fromRGBO(243, 246, 249, 0);
  final borderColor = Colors.grey[800]!;

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: AppColors.primaryColor),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Color(0xffcfdbec), width: 2.0),
      ),
    );

    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Pinput(
              length: 5,
              controller: widget.pinController,
              defaultPinTheme: defaultPinTheme,
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              onCompleted: (pin) {
                logger('onCompleted: $pin');
              },
              onChanged: (value) {
                logger('onChanged: $value');
              },
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    width: 24,
                    height: 2,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.primaryColor, width: 2.0),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: AppColors.primaryColor, width: 2.0),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.redAccent,
                      width: 2.0,
                    ), // خط سفلي عند الخطأ
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
