import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/skeleton.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/accredited_drivers_data_source.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accredited_driver.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view/widgets/accredit_driver_sheet.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view/widgets/accredited_driver_card.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view/widgets/unaccredit_driver_dialog.dart';
import 'package:lavanderia_partner/features/accredited_drivers/presentation/view_model/accredited_drivers_cubits.dart';

/// صفحة الدليفرية المعتمدين عند المغسلة (GET)
/// زرار الاعتماد بيفتح شيت برقم الدليفري (POST)، والإلغاء بعد تأكيد (DELETE)
/// واللستة بتتحدث محلياً بعد الاتنين من غير ما نجيبها تاني
class AccreditedDriversScreen extends StatelessWidget {
  const AccreditedDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = getIt<AccreditedDriversDataSource>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AccreditedDriversCubit(dataSource)..fetchData(),
        ),
        BlocProvider(create: (_) => UnaccreditDriverCubit(dataSource)),
      ],
      child: const _AccreditedDriversView(),
    );
  }
}

class _AccreditedDriversView extends StatelessWidget {
  const _AccreditedDriversView();

  Future<void> _accredit(BuildContext context) async {
    final driver = await showAccreditDriverSheet(context);
    if (driver == null || !context.mounted) return;

    context.read<AccreditedDriversCubit>().prepend(driver);
    context.showSuccessMessage('driver_accredited_success'.tr());
  }

  Future<void> _unaccredit(BuildContext context, AccreditedDriver driver) async {
    final confirmed = await showUnaccreditDriverDialog(
      context,
      driver.fullName,
    );
    if (confirmed != true || !context.mounted) return;

    context.read<UnaccreditDriverCubit>().submit(driver.driverId);
  }

  void _onUnaccreditStateChanged(BuildContext context, BaseState<int> state) {
    if (state.isSuccess && state.data != null) {
      context.read<AccreditedDriversCubit>().removeDriver(state.data!);
      context.showSuccessMessage('driver_unaccredited_success'.tr());
      return;
    }
    // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
    final failure = state.failure;
    if (state.isFailure &&
        (failure is ServerFailure || failure is UnknownFailure)) {
      context.showErrorMessage(failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UnaccreditDriverCubit, BaseState<int>>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onUnaccreditStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        appBar: const CustomAppBar(title: 'accredited_drivers'),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primaryColor,
          onPressed: () => _accredit(context),
          icon: const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColors.whiteColor,
          ),
          label: LocalizedLabel(
            text: 'accredit_driver',
            style: TextStyles.whiteText(14, weight: FontWeight.w700),
          ),
        ),
        body: BlocBuilder<AccreditedDriversCubit, BaseState<AccreditedDriver>>(
          // السحب للتحديث بيسيب اللستة القديمة ظاهرة لحد ما الجديدة توصل
          buildWhen: (previous, current) =>
              !(current.isLoading && previous.isSuccess),
          builder: (context, state) => _buildBody(context, state),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BaseState<AccreditedDriver> state) {
    final cubit = context.read<AccreditedDriversCubit>();
    if (state.isFailure && state.items.isEmpty) {
      return _RetryMessage(onRetry: cubit.fetchData);
    }
    if (state.isInitial || state.isLoading) {
      return const _AccreditedDriversSkeleton();
    }

    final drivers = state.items;
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.fetchData,
      child: drivers.isEmpty
          ? _EmptyState(onAccredit: () => _accredit(context))
          : BlocBuilder<UnaccreditDriverCubit, BaseState<int>>(
              builder: (context, removeState) => ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                // مسافة تحت عشان الزرار العايم مايغطيش آخر كارت
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
                itemCount: drivers.length,
                separatorBuilder: (_, _) => Gap(10.h),
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  final isRemoving =
                      removeState.isLoading &&
                      removeState.data == driver.driverId;
                  return AccreditedDriverCard(
                    key: ValueKey(driver.driverId),
                    driver: driver,
                    isRemoving: isRemoving,
                    onUnaccredit: removeState.isLoading
                        ? null
                        : () => _unaccredit(context, driver),
                  );
                },
              ),
            ),
    );
  }
}

/// مفيش دليفرية معتمدين لسه، وقابلة للسحب عشان التحديث يشتغل
class _EmptyState extends StatelessWidget {
  final VoidCallback onAccredit;

  const _EmptyState({required this.onAccredit});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      children: [
        Gap(110.h),
        Icon(
          Icons.verified_user_outlined,
          size: 56.sp,
          color: AppColors.greyColor5,
        ),
        Gap(14.h),
        LocalizedLabel(
          text: 'no_accredited_drivers',
          textAlign: TextAlign.center,
          style: TextStyles.darkBold14,
        ),
        Gap(6.h),
        LocalizedLabel(
          text: 'accredited_drivers_hint',
          textAlign: TextAlign.center,
          maxLines: 3,
          style: TextStyles.darkRegular12.copyWith(color: AppColors.greyColor3),
        ),
        Gap(8.h),
        Center(
          child: TextButton.icon(
            onPressed: onAccredit,
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryColor),
            label: LocalizedLabel(
              text: 'accredit_driver',
              style: TextStyles.darkBold14.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// رسالة فشل تحميل بزرار إعادة المحاولة
class _RetryMessage extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryMessage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocalizedLabel(
            text: 'accredited_drivers_load_failed',
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(color: AppColors.redColor),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
            label: LocalizedLabel(
              text: 'try_again',
              style: TextStyles.darkBold14.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// لودينج بنفس شكل [AccreditedDriverCard]
class _AccreditedDriversSkeleton extends StatelessWidget {
  const _AccreditedDriversSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      itemCount: 5,
      separatorBuilder: (_, _) => Gap(10.h),
      itemBuilder: (_, _) => Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.lightGreyColor),
        ),
        child: SkeletonShimmer(
          child: Column(
            children: [
              Row(
                children: [
                  SkeletonBox(width: 46.w, height: 46.w, radius: 23.w),
                  Gap(12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 140.w, height: 14.h),
                        Gap(6.h),
                        SkeletonBox(width: 100.w, height: 12.h),
                      ],
                    ),
                  ),
                ],
              ),
              Gap(12.h),
              Row(
                children: [
                  SkeletonBox(width: 110.w, height: 12.h),
                  const Spacer(),
                  SkeletonBox(width: 80.w, height: 24.h, radius: 8.r),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
