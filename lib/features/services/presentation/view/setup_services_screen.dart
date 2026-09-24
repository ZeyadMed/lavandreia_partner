import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
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
import 'package:lavanderia_partner/features/services/presentation/view/widgets/services_skeleton.dart';
import 'package:lavanderia_partner/features/services/presentation/view_model/services_cubits.dart';

/// شاشة إعداد الخدمات، بتظهر مرة واحدة بعد أول تسجيل دخول
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

  Future<void> _onSaveStateChanged(
    BuildContext context,
    BaseState<void> state,
  ) async {
    if (state.isSuccess) {
      await CacheManager.setServicesSetupCompleted();
      if (!context.mounted) return;
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
                    return _RetryMessage(
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
          (service) => _ServiceTile(
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

/// كارت خدمة بيتفتح على أصنافها
/// الأصناف بتتجاب أول مرة الكارت يتفتح بس، مش مع لستة الخدمات
class _ServiceTile extends StatefulWidget {
  final ServiceCategory service;
  final TextEditingController Function(int itemId) controllerFor;

  const _ServiceTile({
    super.key,
    required this.service,
    required this.controllerFor,
  });

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  /// بيتعمل أول ما الكارت يتفتح، وبيفضل عايش عشان مايجيبش الأصناف تاني
  ServiceItemsCubit? _itemsCubit;
  bool _isExpanded = false;

  @override
  void dispose() {
    _itemsCubit?.close();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      _itemsCubit ??= ServiceItemsCubit(
        dataSource: getIt<LaundryServicesDataSource>(),
        serviceId: widget.service.id,
      )..fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        decoration: BoxDecoration(
          color: _isExpanded ? AppColors.secondaryColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _isExpanded
                ? AppColors.primaryColor
                : Colors.grey.withValues(alpha: 0.25),
            width: _isExpanded ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (_isExpanded)
              BlocProvider.value(value: _itemsCubit!, child: _buildItems()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Label(text: widget.service.icon, style: TextStyle(fontSize: 20.sp)),
            Gap(10.w),
            Expanded(
              child: Label(
                text: widget.service.name,
                style: _isExpanded
                    ? TextStyles.blackBold16.copyWith(
                        color: AppColors.primaryColor,
                      )
                    : TextStyles.darkRegular16,
              ),
            ),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: _isExpanded ? AppColors.primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItems() {
    return BlocBuilder<ServiceItemsCubit, BaseState<ServiceItem>>(
      builder: (context, state) {
        final Widget content;
        if (state.isFailure) {
          content = _RetryMessage(
            messageKey: 'items_load_failed',
            onRetry: context.read<ServiceItemsCubit>().fetchData,
          );
        } else if (!state.isSuccess) {
          content = const ServiceItemsSkeleton();
        } else if (state.isEmpty) {
          content = Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: LocalizedLabel(
              text: 'no_service_items',
              textAlign: TextAlign.center,
              style: TextStyles.darkRegular14,
            ),
          );
        } else {
          content = Column(
            children: state.items
                .map(
                  (item) => _ItemPriceRow(
                    item: item,
                    controller: widget.controllerFor(item.id),
                  ),
                )
                .toList(),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 6.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
              Gap(4.h),
              content,
            ],
          ),
        );
      },
    );
  }
}

/// صف صنف واحد: الاسم وحقل السعر
class _ItemPriceRow extends StatelessWidget {
  final ServiceItem item;
  final TextEditingController controller;

  const _ItemPriceRow({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Label(text: item.name, style: TextStyles.darkBold14),
          ),
          Gap(12.w),
          SizedBox(
            width: 120.w,
            height: 44.h,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // أرقام إنجليزي وفاصلة عشرية واحدة بحد أقصى رقمين بعدها
              // الـ $ مهم عشان التحقق يبقى على القيمة كلها مش على جزء منها
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      RegExp(r'^\d*\.?\d{0,2}$').hasMatch(newValue.text)
                      ? newValue
                      : oldValue,
                ),
              ],
              textAlign: TextAlign.center,
              style: TextStyles.darkBold16,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyles.greyColor2Regular14,
                filled: true,
                fillColor: AppColors.whiteColor,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                suffixText: 'currency'.tr(),
                suffixStyle: TextStyles.darkBold12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسالة فشل تحميل بزرار إعادة المحاولة
class _RetryMessage extends StatelessWidget {
  final String messageKey;
  final VoidCallback onRetry;

  const _RetryMessage({required this.messageKey, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalizedLabel(
              text: messageKey,
              textAlign: TextAlign.center,
              style: TextStyles.darkRegular14.copyWith(
                color: AppColors.redColor,
              ),
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
      ),
    );
  }
}

/// نفس الهيدر الأزرق بتاع التسجيل عشان الشاشة تبان تكملة للـ flow
/// من غير زرار رجوع لأن الإعداد لازم يخلص قبل الدخول للرئيسية
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
          LocalizedLabel(
            text: 'setup_services_title',
            style: TextStyles.whiteBold15.copyWith(fontSize: 18.sp),
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
