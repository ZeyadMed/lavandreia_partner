import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // search box skeleton
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Container(width: 140, height: 20, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // list skeletons
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              itemBuilder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 12, width: double.infinity, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(height: 12, width: 150, color: Colors.white),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: 6,
            ),
          ),
        ],
      ),
    );
  }
}
