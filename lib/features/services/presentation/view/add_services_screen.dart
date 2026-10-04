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
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/services/data/laundry_services_data_source.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/service_price_tile.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/services_skeleton.dart';
import 'package:lavanderia_partner/features/services/presentation/view_model/services_cubits.dart';

/// إضافة أصناف جديدة من الخدمات المتاحة لمغسلة عندها أصناف أصلاً
/// بتبعت POST فيه الأصناف الجديدة بس
/// بترجع true لو الإضافة نجحت عشان صفحة الخدمات تجيب اللستة تاني
class AddServicesScreen extends StatelessWidget {
  /// الـ serviceItemIds اللي عند المغسلة أصلاً، بتظهر "مضاف" ومش بتتبعت
  final Set<int> addedItemIds;

  const AddServicesScreen({super.key, required this.addedItemIds});

  @override
  Widget build(BuildContext context) {
    final dataSource = getIt<LaundryServicesDataSource>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ServicesCubit(dataSource)..fetchData()),
        BlocProvider(create: (_) => AddMyServicesCubit(dataSource)),
      ],
      child: _AddServicesView(addedItemIds: addedItemIds),
    );
  }
}

class _AddServicesView extends StatefulWidget {
  final Set<int> addedItemIds;

  const _AddServicesView({required this.addedItemIds});

  @override
  State<_AddServicesView> createState() => _AddServicesViewState();
}

class _AddServicesViewState extends State<_AddServicesView> {
  /// كنترولر سعر لكل صنف جديد بالـ id، عشان الأسعار ماتضيعش لما الخدمة تتقفل
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

  /// الأصناف الجديدة اللي ليها سعر أكبر من صفر بس
  List<ServiceItemPrice> _collectNewPrices() => [
    for (final entry in _priceControllers.entries)
      if ((double.tryParse(entry.value.text.trim()) ?? 0) > 0)
        ServiceItemPrice(
          serviceItemId: entry.key,
          price: double.parse(entry.value.text.trim()),
        ),
  ];

  void _submit() {
    final newPrices = _collectNewPrices();
    if (newPrices.isEmpty) {
      context.showErrorMessage('enter_at_least_one_price'.tr());
      return;
    }
    context.read<AddMyServicesCubit>().submit(newPrices);
  }

  void _onSubmitStateChanged(
    BuildContext context,
    BaseState<List<ServiceItemPrice>> state,
  ) {
    if (state.isSuccess) {
      Navigator.of(context).pop(true);
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
    return BlocListener<AddMyServicesCubit, BaseState<List<ServiceItemPrice>>>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onSubmitStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        appBar: const CustomAppBar(title: 'add_service'),
        body: BlocBuilder<ServicesCubit, BaseState<ServiceCategory>>(
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
            return Column(
              children: [
                Expanded(child: _buildServicesList(state.items)),
                BlocBuilder<
                  AddMyServicesCubit,
                  BaseState<List<ServiceItemPrice>>
                >(
                  builder: (context, submitState) => _SubmitBar(
                    isSubmitting: submitState.isLoading,
                    onSubmit: _submit,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildServicesList(List<ServiceCategory> services) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
      children: [
        LocalizedLabel(
          text: 'add_service_hint',
          textAlign: TextAlign.center,
          style: TextStyles.darkRegular16.copyWith(color: AppColors.greyColor3),
        ),
        Gap(16.h),
        for (final service in services)
          ServicePriceTile(
            // الـ key بيربط الـ cubit بالخدمة لما الليست تعيد استخدام الويدجت
            key: ValueKey(service.id),
            service: service,
            controllerFor: _controllerFor,
            addedItemIds: widget.addedItemIds,
          ),
      ],
    );
  }
}

/// زرار الإضافة ثابت تحت، وبيتقفل وقت الإرسال عشان مايتبعتش مرتين
class _SubmitBar extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitBar({required this.isSubmitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(5.w, 14.h, 5.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: CustomButton(
          onPressed: isSubmitting ? () {} : onSubmit,
          title: isSubmitting ? 'saving' : 'add_selected_items',
          backgroundColor: isSubmitting
              ? AppColors.primaryColor.withValues(alpha: 0.6)
              : AppColors.primaryColor,
        ),
      ),
    );
  }
}
