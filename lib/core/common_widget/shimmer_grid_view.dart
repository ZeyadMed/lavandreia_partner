import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/widget/custom_shimmer_widget.dart';

class ShimmerGridView extends StatelessWidget {
  const ShimmerGridView({super.key, this.count, this.childAspectRatio});

  final int? count;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      itemCount: count ?? 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio ?? 1.5,
      ),
      itemBuilder: (context, index) {
        return const CustomShimmerWidget(height: 40, width: double.infinity);
      },
    );
  }
}
