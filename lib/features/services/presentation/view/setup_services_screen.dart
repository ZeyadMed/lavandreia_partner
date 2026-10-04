import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/common_widget/loading_button.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/services/data/laundry_services_data_source.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/service_price_tile.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/services_skeleton.dart';
import 'package:lavanderia_partner/features/services/presentation/view_model/services_cubits.dart';

/// شاشة إعداد الخدمات، بتظهر بعد اللوجين لو السيرفر رجّع hasServices بـ false
/// الخدمات بتيجي من السيرفر، وكل خدمة بتتفتح على أصنافها وكل صنف ليه سعر
class SetupServicesScreen extends StatelessWidget {
  const SetupServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = getIt<LaundryServicesDataSource>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ServicesCubit(dataSource)..fetchData()),
        BlocProvider(create: (_) => SaveMyServicesCubit(dataSource)),
      ],
      child: const _SetupServicesView(),
    );
  }
}

class _SetupServicesView extends StatefulWidget {
  const _SetupServicesView();

  @override
  State<_SetupServicesView> createState() => _SetupServicesViewState();
}

class _SetupServicesViewState extends State<_SetupServicesView> {
  /// كنترولر سعر لكل صنف بالـ id، متشال هنا مش جوه الخدمة
  /// عشان الأسعار ماتضيعش لما الخدمة تتقفل أو تخرج بره الشاشة وهي بتسكرول
  final Map<int, TextEditingController> _priceControllers = {};

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int itemId) =>
      _priceControllers.putIfAbsent(itemId, TextEditingController.new);

  /// الأصناف اللي ليها سعر أكبر من صفر بس، الفاضي معناه إن المغسلة مش بتقدمه
  List<ServiceItemPrice> _collectPrices() => [
    for (final entry in _priceControllers.entries)
      if ((double.tryParse(entry.value.text.trim()) ?? 0) > 0)
        ServiceItemPrice(
          serviceItemId: entry.key,
          price: double.parse(entry.value.text.trim()),
        ),
  ];

  void _submit() {
    final prices = _collectPrices();
    if (prices.isEmpty) {
      context.showErrorMessage('enter_at_least_one_price'.tr());
      return;
    }
    context.read<SaveMyServicesCubit>().save(prices);
  }

  void _onSaveStateChanged(BuildContext context, BaseState<void> state) {
    if (state.isSuccess) {
      context.go(AppRouter.initialRoot);
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
    return BlocListener<SaveMyServicesCubit, BaseState<void>>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onSaveStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body: Column(
          children: [
            const _SetupHeader(),
            Expanded(
              child: BlocBuilder<ServicesCubit, BaseState<ServiceCategory>>(
                builder: (context, state) {
                  if (state.isFailure) {
                    return ServicesRetryMessage(
                      messageKey: 'services_load_failed',
                      onRetry: context.read<ServicesCubit>().fetchData,
                    );
                  }
                  if (!state.isSuccess) {
                    return const SetupServicesSkeleton();
                  }
                  return _buildServicesList(state.items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList(List<ServiceCategory> services) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 30.h),
      children: [
        LocalizedLabel(
          text: 'choose_your_services',
          textAlign: TextAlign.center,
          style: TextStyles.darkRegular16.copyWith(color: AppColors.greyColor3),
        ),
        Gap(16.h),

        ...services.map(
          (service) => ServicePriceTile(
            // الـ key بيربط الـ cubit بالخدمة لما الليست تعيد استخدام الويدجت
            key: ValueKey(service.id),
            service: service,
            controllerFor: _controllerFor,
          ),
        ),

        Gap(20.h),
        BlocBuilder<SaveMyServicesCubit, BaseState<void>>(
          builder: (context, state) => state.isLoading
              ? const Center(child: LoadingButton())
              : CustomButton(onPressed: _submit, title: 'save'.tr()),
        ),
      ],
    );
  }
}

/// نفس الهيدر الأزرق بتاع التسجيل عشان الشاشة تبان تكملة للـ flow
/// من غير زرار رجوع، وفيه زرار تخطي بيودي للرئيسية على طول
class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        bottom: 18.h,
        left: 16.w,
        right: 16.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LocalizedLabel(
                  text: 'setup_services_title',
                  style: TextStyles.whiteBold15.copyWith(fontSize: 18.sp),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRouter.initialRoot),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.whiteColor,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: LocalizedLabel(
                  text: 'skip',
                  style: TextStyles.whiteBold14,
                ),
              ),
            ],
          ),
          Gap(4.h),
          LocalizedLabel(
            text: 'setup_services_subtitle',
            maxLines: 2,
            style: TextStyles.whiteBold14.copyWith(
              fontWeight: FontWeight.w300,
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
