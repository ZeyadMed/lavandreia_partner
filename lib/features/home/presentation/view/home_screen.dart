import 'package:flutter/material.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/features/home/presentation/view/widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      body: Column(
        children: [
          HomeHeader(
            // مؤقتاً لحد ما نربط بيانات المغسلة من الـ API
            laundryName: 'مغسلة المدينة',
            isAvailable: isAvailable,
            onAvailabilityChanged: (value) {
              setState(() => isAvailable = value);
            },
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
