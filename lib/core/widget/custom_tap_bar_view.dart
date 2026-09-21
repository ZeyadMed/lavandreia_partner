import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';

class CustomTabBarView extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> views;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;

  const CustomTabBarView({
    super.key,
    required this.tabs,
    required this.views,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
  }) : assert(tabs.length == views.length, 'Tabs and Views must be equal');

  @override
  State<CustomTabBarView> createState() => _CustomTabBarViewState();
}

class _CustomTabBarViewState extends State<CustomTabBarView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            // indicatorPadding: const EdgeInsets.symmetric(horizontal: ),
            // indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: widget.tabs
                .map(
                  (text) =>
                      LocalizedLabel(text: text, style: TextStyles.darkBold14),
                )
                .toList(),
            dividerColor: Colors.transparent,
            isScrollable: false,
            labelPadding: const EdgeInsets.symmetric(vertical: 16),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: widget.labelColor ?? AppColors.primaryColor,
            unselectedLabelColor:
                widget.unselectedLabelColor ?? Colors.grey.shade600,
            labelStyle: widget.labelStyle ?? TextStyles.darkBold14,
            unselectedLabelStyle:
                widget.unselectedLabelStyle ?? TextStyles.darkBold14,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: widget.views,
          ),
        ),
      ],
    );
  }
}
