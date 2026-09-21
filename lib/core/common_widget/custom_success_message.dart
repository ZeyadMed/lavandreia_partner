import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class CustomSuccessOverlay {
  static void show({
    required BuildContext context,
    required String text,
    Color? backgroundColor,
  }) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 5,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.greenColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text.tr(),
                    style: TextStyles.darkRegular16.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
