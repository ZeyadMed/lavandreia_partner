import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_tap_bar_view.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    Key? key,
    this.width,
    required this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class ClinicsListShimmer extends StatelessWidget {
  const ClinicsListShimmer({super.key});

  Widget _searchPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: const [
          Expanded(child: ShimmerBox(height: 48, width: double.infinity)),
        ],
      ),
    );
  }

  Widget _clinicItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: const [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: ShimmerBox(
              height: 60,
              width: 60,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          Gap(20),
          Expanded(child: ShimmerBox(height: 16, width: double.infinity)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _searchPlaceholder(),
          const Gap(10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, __) => _clinicItem(),
            separatorBuilder: (_, __) => const Gap(10),
            itemCount: 8,
          ),
        ],
      ),
    );
  }
}

class DoctorsListShimmer extends StatelessWidget {
  const DoctorsListShimmer({Key? key}) : super(key: key);

  Widget _searchPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: const [
          Expanded(child: ShimmerBox(height: 48, width: double.infinity)),
        ],
      ),
    );
  }

  Widget _doctorItem() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: const BoxDecoration(color: Color(0xfff7f7f7)),
            child: Row(
              children: const [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                  child: ShimmerBox(
                    height: 60,
                    width: 60,
                    borderRadius: BorderRadius.all(Radius.circular(60)),
                  ),
                ),
                Gap(20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 16, width: double.infinity),
                      Gap(5),
                      ShimmerBox(height: 14, width: double.infinity),
                      Gap(5),
                      Row(
                        children: [
                          ShimmerBox(height: 14, width: 40),
                          Gap(10),
                          ShimmerBox(height: 14, width: 40),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Gap(10),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(height: 14, width: 140),
                    Gap(8),
                    ShimmerBox(height: 14, width: 120),
                  ],
                ),
                Gap(10),
                Row(
                  children: [
                    ShimmerBox(height: 14, width: 140),
                    Gap(8),
                    ShimmerBox(height: 14, width: 80),
                  ],
                ),
                Gap(10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(child: ShimmerBox(height: 14, width: 80)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _searchPlaceholder(),
          const Gap(10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, __) => _doctorItem(),
            separatorBuilder: (_, __) => const Gap(10),
            itemCount: 6,
          ),
        ],
      ),
    );
  }
}

class ClinicDetailsShimmer extends StatelessWidget {
  const ClinicDetailsShimmer({Key? key}) : super(key: key);

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const ShimmerBox(
              height: 80,
              width: 80,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          const Gap(20),
          const ShimmerBox(
            height: 18,
            width: 140,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [ShimmerBox(height: 14, width: 80)],
          ),
          const Divider(color: Colors.grey, height: 30, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: const [
                  ShimmerBox(height: 16, width: 90),
                  Gap(8),
                  ShimmerBox(height: 18, width: 60),
                ],
              ),
              Column(
                children: const [
                  ShimmerBox(height: 16, width: 90),
                  Gap(8),
                  ShimmerBox(height: 18, width: 60),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(height: 20, width: 120),
          Gap(12),
          ShimmerBox(height: 14, width: double.infinity),
          Gap(6),
          ShimmerBox(height: 14, width: double.infinity),
          Gap(6),
          ShimmerBox(height: 14, width: 220),
        ],
      ),
    );
  }

  Widget _branchesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(height: 20, width: 120),
          Gap(12),
          ShimmerBox(height: 14, width: double.infinity),
          Gap(6),
          ShimmerBox(height: 14, width: double.infinity),
          Gap(6),
          ShimmerBox(height: 14, width: 200),
        ],
      ),
    );
  }

  Widget _specialistsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(height: 20, width: 120),
          Gap(12),
          ShimmerBox(height: 14, width: double.infinity),
          Gap(6),
          ShimmerBox(height: 14, width: double.infinity),
        ],
      ),
    );
  }

  Widget _doctorsList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8.0),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              ShimmerBox(
                height: 56,
                width: 56,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(height: 16, width: double.infinity),
                    Gap(6),
                    ShimmerBox(height: 14, width: 160),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const Gap(10),
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          _header(context),
          const Gap(10),
          SizedBox(
            height: 400,
            child: CustomTabBarView(
              indicatorColor: AppColors.primaryColor,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: AppColors.greyColor,
              labelStyle: TextStyles.greyColor2Regular14,
              unselectedLabelStyle: TextStyles.greyColor2Regular14,
              tabs: ["aboutClinic", "doctors"],
              views: [
                // About tab placeholders
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      _aboutSection(),
                      const Gap(10),
                      _branchesSection(),
                      const Gap(10),
                      _specialistsSection(),
                    ],
                  ),
                ),
                // Doctors tab placeholders
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(children: [_doctorsList()]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorDetailsShimmer extends StatelessWidget {
  const DoctorDetailsShimmer({Key? key}) : super(key: key);

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: const [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: ShimmerBox(
              height: 60,
              width: 60,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 18, width: double.infinity),
                Gap(10),
                ShimmerBox(height: 14, width: 120),
                Gap(10),
                ShimmerBox(height: 14, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _branchList() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          const ShimmerBox(height: 18, width: 160),
          const Gap(12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (context, index) => const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: ShimmerBox(
                  height: 70,
                  width: 70,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingTimes() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        separatorBuilder: (_, __) => const Gap(12),
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1),
              color: Colors.white,
            ),
            child: Column(
              children: const [
                ShimmerBox(height: 36, width: double.infinity),
                Gap(12),
                ShimmerBox(height: 14, width: 60),
                Gap(8),
                ShimmerBox(height: 14, width: 40),
                Gap(12),
                ShimmerBox(height: 20, width: double.infinity),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(height: 18, width: 120),
          Gap(10),
          ShimmerBox(height: 14, width: double.infinity),
          Gap(6),
          ShimmerBox(height: 14, width: double.infinity),
          Gap(6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _header(),
          Gap(30),
          _branchList(),
          Gap(20),
          _bookingTimes(),
          Gap(12),
          _infoSection(),
        ],
      ),
    );
  }
}
