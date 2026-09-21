import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class DefaultExpansionTile extends StatefulWidget {
  final String name;
  final String image;
  final List? options;
  final List<Widget>? optionsWidget;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final double radius;
  final bool initiallyExpanded;

  /// سطر صغير تحت الاسم زي "6 خدمة متاحة"
  final String? subtitle;

  /// ويدجت على جنب الهيدر زي البادج بتاعة عدد القطع المختارة
  final Widget? trailing;

  /// لو true الهيدر بيبقى فاتح (أبيض) والنص غامق بدل الهيدر الأزرق الافتراضي
  final bool lightHeader;

  /// مسافة جوه البودي الأبيض اللي بيلف الـ children
  final EdgeInsetsGeometry? childrenPadding;

  const DefaultExpansionTile({
    super.key,
    required this.name,
    this.image = '',
    this.options,
    this.onTap,
    this.optionsWidget,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.radius = 0,
    this.initiallyExpanded = false,
    this.subtitle,
    this.trailing,
    this.lightHeader = false,
    this.childrenPadding,
  });

  @override
  State<DefaultExpansionTile> createState() => _DefaultExpansionTileState();
}

class _DefaultExpansionTileState extends State<DefaultExpansionTile> {
  bool isOpen = false;
  int? isSelected;
  String lastChoice = '';

  @override
  Widget build(BuildContext context) {
    // في الوضع الفاتح الهيدر أبيض والنص والأيقونات غامقة
    final headerBackground =
        widget.backgroundColor ??
        (widget.lightHeader ? AppColors.whiteColor : AppColors.primaryColor);
    final headerForeground = widget.lightHeader
        ? widget.textColor ?? AppColors.darkTextColor
        : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        collapsedTextColor: headerForeground,
        textColor: headerForeground,
        initiallyExpanded: widget.initiallyExpanded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          side: !isOpen && !widget.lightHeader
              ? const BorderSide(color: Colors.grey, width: 0.5)
              : BorderSide.none,
        ),
        // Keep header color the same whether expanded or not
        backgroundColor: headerBackground,
        collapsedBackgroundColor: headerBackground,
        iconColor: widget.iconColor ?? headerForeground,
        collapsedIconColor: widget.iconColor ?? headerForeground,
        onExpansionChanged: (value) {
          setState(() {
            isOpen = value;
          });
        },
        // في الوضع الفاتح الصورة بتيجي على اليمين مع الاسم بدل الـ leading
        leading: widget.lightHeader || widget.image.isEmpty ? null : _leading(),
        trailing: widget.trailing == null ? null : _trailing(headerForeground),
        title: _title(headerForeground),
        // Wrap the expanded body in a white container so children appear on white
        children: [
          Container(
            width: double.infinity,
            padding: widget.childrenPadding,
            decoration: BoxDecoration(
              color: widget.lightHeader ? headerBackground : Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(widget.radius),
                bottomRight: Radius.circular(widget.radius),
              ),
            ),
            child: Column(children: widget.optionsWidget ?? options(context)),
          ),
        ],
      ),
    );
  }

  /// البادج على جنب الهيدر جنب سهم الفتح
  Widget _trailing(Color foreground) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.trailing!,
        SizedBox(width: 8.w),
        Icon(
          isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: widget.iconColor ?? foreground,
        ),
      ],
    );
  }

  Widget _leading() {
    // السيرفر ممكن يبعت لينك صورة أو إيموجي، فبنفرق بينهم هنا
    final isUrl = widget.image.startsWith('http');
    if (!isUrl) {
      return SizedBox(
        width: 30.w,
        height: 30.w,
        child: Center(
          child: Text(widget.image, style: TextStyle(fontSize: 22.sp)),
        ),
      );
    }

    return Image.network(
      widget.image,
      width: 30.w,
      height: 30.h,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: 30.w, height: 30.w),
    );
  }

  Widget _title(Color foreground) {
    final title = Text(
      widget.name,
      style: TextStyles.blackBold12.copyWith(
        fontSize: 15.sp,
        color: widget.lightHeader
            ? foreground
            : (isOpen
                  ? Colors.white
                  : widget.textColor ?? AppColors.blackColor),
        fontWeight: widget.lightHeader ? FontWeight.bold : FontWeight.w500,
      ),
    );

    if (widget.subtitle == null && !widget.lightHeader) return title;

    // العنوان والسطر اللي تحته، وقبلهم الصورة في الوضع الفاتح
    // start بيبقى ناحية الصورة، يعني يمين في العربي وشمال في الإنجليزي
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        if (widget.subtitle != null) ...[
          SizedBox(height: 2.h),
          Text(
            widget.subtitle!,
            style: TextStyles.greyColor2Regular14.copyWith(fontSize: 11.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    if (!widget.lightHeader || widget.image.isEmpty) return texts;

    // الصورة في بداية الصف يعني قبل الاسم على اليمين في العربي
    // وبتتقلب لوحدها على الشمال في الإنجليزي
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _leading(),
        SizedBox(width: 10.w),
        Flexible(child: texts),
      ],
    );
  }

  List<Widget> options(BuildContext context) =>
      List.generate((widget.options ?? []).length, (index) {
        return InkWell(
          onTap: () {
            widget.onTap?.call(index);
          },
          child: Container(
            width: double.infinity,
            // بتتقلب لوحدها حسب اللغة
            alignment: AlignmentDirectional.centerStart,
            padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
            margin: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              border: Border.all(color: AppColors.greyColor.withOpacity(.5)),
            ),
            child: Text(
              (widget.options ?? [])[index],
              style: TextStyle(
                fontSize: 15.sp,
                color: AppColors.lightTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      });
}
