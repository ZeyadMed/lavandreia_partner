import 'package:flutter/material.dart';

class SocialMediaWidget extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final void Function()? onTap;
  const SocialMediaWidget({
    super.key,
    required this.image,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        image,
        width: width ?? 35,
        height: height ?? 35,
      ),
    );
  }
}
