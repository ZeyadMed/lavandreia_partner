import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/internet_connenction/internet_connenction_cubit.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/style/assets.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';

/// بتظهر مكان الأبلكيشن كله لما النت يفصل، ولما يرجع بتختفي لوحدها؛
/// وزرار إعادة المحاولة بيتأكد من الاتصال فعلاً، ولو النت لسه مش راجع
/// بيقول كده بدل ما يفضل ساكت
class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    if (_checking) return;
    setState(() => _checking = true);
    final online = await context.read<InternetCubit>().retry();
    // لو النت رجع الشاشة بتتشال لوحدها
    if (!mounted) return;
    setState(() => _checking = false);
    if (!online) context.showErrorMessage("stillNoInternet".tr());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(Assets.assetsIconsLottieJson, height: 200.h),
                Gap(20.h),
                Text(
                  "noInternet".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyles.darkBold20.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: Text(
                    "checkInternet".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyles.darkRegular14.copyWith(
                      color: AppColors.greyColor,
                    ),
                  ),
                ),
                Gap(30.h),
                CustomButton(
                  title: "retry",
                  isIcon: _checking,
                  icon: _checking
                      ? SizedBox.square(
                          dimension: 18.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  borderRadius: 30.r,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  fontWeight: FontWeight.w500,
                  onPressed: _retry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
