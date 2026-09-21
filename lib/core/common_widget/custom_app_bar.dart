import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.bottom,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.titleStyle,
  });
  final String? title;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: LocalizedLabel(
        text: title ?? "Not Found".tr(),
        style: titleStyle ?? TextStyles.darkBold20,
      ),
      backgroundColor: backgroundColor ?? Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: true,
      bottom: bottom,
      actions: actions,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
