import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';

class CarouselSliderWidget extends StatefulWidget {
  final List<Widget> widgets;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Color? indecatorColor;

  const CarouselSliderWidget({
    super.key,
    required this.widgets,
    this.height = 400,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.indecatorColor,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CarouselSliderWidgetState createState() => _CarouselSliderWidgetState();
}

class _CarouselSliderWidgetState extends State<CarouselSliderWidget> {
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  _CarouselSliderWidgetState();

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      _currentPage++;
      if (_currentPage >= widget.widgets.length) {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Carousel Image
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.widgets.length,
            itemBuilder: (context, index) {
              return Center(child: widget.widgets[index]);
            },
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
          ),
        ),

        // // Dot Indicator
        Positioned(
          bottom: 5,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.widgets.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryColor
                        : Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
