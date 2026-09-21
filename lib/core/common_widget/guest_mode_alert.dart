import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class GeustModeAlert extends StatelessWidget {
  final String? title;
  const GeustModeAlert({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Alert'.tr(), style: TextStyles.darkBold18),
      content: Text(
        title ?? 'Please log in first'.tr(),
        style: TextStyles.darkRegular14,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('cancel'.tr(), style: TextStyles.darkRegular14),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            GoRouter.of(context).pushReplacement(AppRouter.login);
          },
          child: Text(
            'login'.tr(),
            style: TextStyles.darkRegular14.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
