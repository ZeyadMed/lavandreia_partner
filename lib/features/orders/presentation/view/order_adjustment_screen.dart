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
import 'package:lavanderia_partner/features/orders/data/models/order_adjustment.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_actions_panel.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/submit_adjustment_cubit.dart';
import 'package:lavanderia_partner/features/services/data/laundry_services_data_source.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';
import 'package:lavanderia_partner/features/services/presentation/view_model/services_cubits.dart';

/// اللي حصل لكل قطعة في الطلب لما المغسلة عدّت الهدوم
enum _ItemOutcome { matched, missing, replaced }

/// قرار المغسلة على قطعة واحدة، والصنف البديل لو وصل صنف تاني
class _ItemDecision {
  final _ItemOutcome outcome;
  final MyServiceItem? replacement;
  final int quantity;

  const _ItemDecision({
    this.outcome = _ItemOutcome.matched,
    this.replacement,
    this.quantity = 1,
  });
}

/// قطعة زيادة وصلت ومكانتش في الطلب
class _AddedItem {
  final MyServiceItem item;
  final int quantity;

  const _AddedItem({required this.item, this.quantity = 1});
}

/// صفحة تعديل الطلب لما الهدوم اللي وصلت تختلف عن اللي العميل طلبه
/// بتقفل بـ true لما التعديل يتبعت، والطلب بيستنى رد العميل
class OrderAdjustmentScreen extends StatefulWidget {
  final PartnerOrder order;

  const OrderAdjustmentScreen({super.key, required this.order});

  @override
  State<OrderAdjustmentScreen> createState() => _OrderAdjustmentScreenState();
}

class _OrderAdjustmentScreenState extends State<OrderAdjustmentScreen> {
  /// أصناف المغسلة بأسعارها، منها بنختار البديل والقطع الزيادة
  late final MyServicesCubit _servicesCubit = MyServicesCubit(
    getIt<LaundryServicesDataSource>(),
  )..fetchData();

  final SubmitAdjustmentCubit _submitCubit = SubmitAdjustmentCubit(
    getIt<OrdersDataSource>(),
  );

  /// القطع اللي هترجع للعميل مينفعش تتعدل تاني
  late final List<PartnerOrderItem> _items = widget.order.items
      .where((item) => !item.isReturned)
      .toList();

  /// متعلّم بالـ id بتاع القطعة، والقطعة اللي مش هنا مطابقة
  final Map<int, _ItemDecision> _decisions = {};

  final List<_AddedItem> _added = [];

  @override
  void dispose() {
    _servicesCubit.close();
    _submitCubit.close();
    super.dispose();
  }

  _ItemDecision _decisionOf(PartnerOrderItem item) =>
      _decisions[item.id] ?? const _ItemDecision();

  /// الصنف البديل لازم يتختار قبل ما القطعة تتعلّم إن وصل صنف تاني
  Future<void> _setOutcome(PartnerOrderItem item, _ItemOutcome outcome) async {
    if (outcome != _ItemOutcome.replaced) {
      setState(() => _decisions[item.id] = _ItemDecision(outcome: outcome));
      return;
    }
    final replacement = await _pickServiceItem();
    if (replacement == null || !mounted) return;
    setState(
      () => _decisions[item.id] = _ItemDecision(
        outcome: _ItemOutcome.replaced,
        replacement: replacement,
        quantity: item.quantity,
      ),
    );
  }

  Future<void> _addItem() async {
    final picked = await _pickServiceItem();
    if (picked == null || !mounted) return;
    setState(() => _added.add(_AddedItem(item: picked)));
  }

  Future<MyServiceItem?> _pickServiceItem() {
    return showModalBottomSheet<MyServiceItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ServiceItemPicker(cubit: _servicesCubit),
    );
  }

  List<OrderAdjustmentEntry> get _entries => [
    for (final item in _items)
      ...switch (_decisionOf(item)) {
        _ItemDecision(outcome: _ItemOutcome.missing) => [
          OrderAdjustmentEntry(
            action: OrderAdjustmentAction.remove,
            orderItemId: item.id,
          ),
        ],
        _ItemDecision(
          outcome: _ItemOutcome.replaced,
          :final replacement?,
          :final quantity,
        ) =>
          [
            OrderAdjustmentEntry(
              action: OrderAdjustmentAction.replace,
              orderItemId: item.id,
              newServiceItemId: replacement.serviceItemId,
              newQuantity: quantity,
            ),
          ],
        _ => const <OrderAdjustmentEntry>[],
      },
    for (final added in _added)
      OrderAdjustmentEntry(
        action: OrderAdjustmentAction.add,
        newServiceItemId: added.item.serviceItemId,
        newQuantity: added.quantity,
      ),
  ];

  /// الإجمالي التقريبي بعد التعديل من أسعار المغسلة، للعرض بس
  /// السيرفر هو اللي بيحسب الرقم النهائي بعد رد العميل
  double get _estimatedItemsTotal {
    var total = 0.0;
    for (final item in _items) {
      final decision = _decisionOf(item);
      total += switch (decision.outcome) {
        _ItemOutcome.matched => item.lineTotal,
        _ItemOutcome.missing => 0,
        _ItemOutcome.replaced =>
          (decision.replacement?.price ?? 0) * decision.quantity,
      };
    }
    for (final added in _added) {
      total += added.item.price * added.quantity;
    }
    return total;
  }

  void _onSubmitStateChanged(
    BuildContext context,
    BaseState<PartnerOrder> state,
  ) {
    if (state.isSuccess) {
      context.showSuccessMessage('adjustment_sent'.tr());
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
    final entries = _entries;

    return BlocListener<SubmitAdjustmentCubit, BaseState<PartnerOrder>>(
      bloc: _submitCubit,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onSubmitStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        appBar: const CustomAppBar(title: 'adjust_order'),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: [
                  LocalizedLabel(
                    text: 'adjust_order_hint',
                    style: TextStyles.darkRegular14.copyWith(
                      color: AppColors.greyColor3,
                    ),
                  ),
                  Gap(14.h),
                  DetailsCard(
                    titleKey: 'ordered_items',
                    child: Column(
                      children: [
                        for (final item in _items)
                          _AdjustItemRow(
                            item: item,
                            decision: _decisionOf(item),
                            onOutcomeSelected: (outcome) =>
                                _setOutcome(item, outcome),
                            onQuantityChanged: (quantity) => setState(
                              () => _decisions[item.id] = _ItemDecision(
                                outcome: _ItemOutcome.replaced,
                                replacement: _decisionOf(item).replacement,
                                quantity: quantity,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Gap(14.h),
                  DetailsCard(
                    titleKey: 'extra_items',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < _added.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _ServiceItemLine(
                              item: _added[i].item,
                              quantity: _added[i].quantity,
                              onQuantityChanged: (quantity) => setState(
                                () => _added[i] = _AddedItem(
                                  item: _added[i].item,
                                  quantity: quantity,
                                ),
                              ),
                              onRemove: () =>
                                  setState(() => _added.removeAt(i)),
                            ),
                          ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: AppColors.primaryColor,
                          ),
                          label: LocalizedLabel(
                            text: 'add_extra_item',
                            style: TextStyles.darkBold14.copyWith(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<SubmitAdjustmentCubit, BaseState<PartnerOrder>>(
              bloc: _submitCubit,
              builder: (context, state) => _SubmitBar(
                oldTotal: widget.order.itemsTotal,
                newTotal: _estimatedItemsTotal,
                isLoading: state.isLoading,
                onSubmit: entries.isEmpty
                    ? null
                    : () => _submitCubit.submit(widget.order, entries),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قطعة من الطلب وتحتها اختيارات: مطابق، مجاش، وصل صنف تاني
class _AdjustItemRow extends StatelessWidget {
  final PartnerOrderItem item;
  final _ItemDecision decision;
  final ValueChanged<_ItemOutcome> onOutcomeSelected;
  final ValueChanged<int> onQuantityChanged;

  const _AdjustItemRow({
    required this.item,
    required this.decision,
    required this.onOutcomeSelected,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final replacement = decision.replacement;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Label(
                  text: item.name,
                  maxLines: 1,
                  style: TextStyles.boldStyle(15, weight: FontWeight.w700),
                ),
              ),
              Label(
                text: '× ${item.quantity}  •  ${formatAmount(item.lineTotal)}',
                maxLines: 1,
                style: TextStyles.darkRegular12.copyWith(
                  color: AppColors.greyColor4,
                ),
              ),
            ],
          ),
          Gap(10.h),
          Row(
            children: [
              for (final outcome in _ItemOutcome.values) ...[
                Expanded(
                  child: _OutcomeChip(
                    outcome: outcome,
                    isSelected: decision.outcome == outcome,
                    onTap: () => onOutcomeSelected(outcome),
                  ),
                ),
                if (outcome != _ItemOutcome.values.last) Gap(8.w),
              ],
            ],
          ),
          if (decision.outcome == _ItemOutcome.replaced &&
              replacement != null) ...[
            Gap(10.h),
            _ServiceItemLine(
              item: replacement,
              quantity: decision.quantity,
              onTap: () => onOutcomeSelected(_ItemOutcome.replaced),
              onQuantityChanged: onQuantityChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _OutcomeChip extends StatelessWidget {
  final _ItemOutcome outcome;
  final bool isSelected;
  final VoidCallback onTap;

  const _OutcomeChip({
    required this.outcome,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (labelKey, color) = switch (outcome) {
      _ItemOutcome.matched => ('item_matched', const Color(0xff0E8C4F)),
      _ItemOutcome.missing => ('item_missing', AppColors.redColor2),
      _ItemOutcome.replaced => ('item_replaced', const Color(0xffC2410C)),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 9.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : AppColors.semiWhiteColor2,
          ),
        ),
        child: LocalizedLabel(
          text: labelKey,
          maxLines: 1,
          style: TextStyles.boldStyle(
            12,
            color: isSelected ? color : AppColors.greyColor4,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// صنف من أصناف المغسلة بسعره وجنبه الكمية
/// [onRemove] بيظهر أيقونة حذف، و [onTap] بيخلي الاسم يتغير
class _ServiceItemLine extends StatelessWidget {
  final MyServiceItem item;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _ServiceItemLine({
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.semiWhiteColor3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    text: item.serviceItemName,
                    maxLines: 1,
                    style: TextStyles.darkBold14.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Gap(2.h),
                  Label(
                    text: '${item.serviceName} • ${formatAmount(item.price)}',
                    maxLines: 1,
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.greyColor4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _QuantityStepper(value: quantity, onChanged: onQuantityChanged),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20.sp,
                color: AppColors.redColor2,
              ),
            ),
        ],
      ),
    );
  }
}

/// زرارين + و - وبينهم الكمية، أقل حاجة 1
class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 30.w,
          child: Label(
            text: '$value',
            textAlign: TextAlign.center,
            style: TextStyles.darkBold14,
          ),
        ),
        _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(value + 1)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.semiWhiteColor2),
        ),
        child: Icon(
          icon,
          size: 16.sp,
          color: onTap == null ? AppColors.greyColor5 : AppColors.primaryColor,
        ),
      ),
    );
  }
}

/// الشريط اللي تحت: الإجمالي القديم والتقريبي الجديد وزرار الإرسال
class _SubmitBar extends StatelessWidget {
  final double oldTotal;
  final double newTotal;
  final bool isLoading;

  /// null لو مفيش ولا تعديل لسه
  final VoidCallback? onSubmit;

  const _SubmitBar({
    required this.oldTotal,
    required this.newTotal,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        14.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 14.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LocalizedLabel(
                text: 'estimated_items_total',
                style: TextStyles.darkRegular14.copyWith(
                  color: AppColors.greyColor4,
                ),
              ),
              const Spacer(),
              if (oldTotal != newTotal) ...[
                Label(
                  text: formatAmount(oldTotal),
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.greyColor5,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Gap(8.w),
              ],
              Label(
                text: formatAmount(newTotal),
                style: TextStyles.boldStyle(
                  17,
                  color: AppColors.primaryColor,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Gap(12.h),
          Opacity(
            opacity: onSubmit == null ? 0.5 : 1,
            child: OrderActionButton(
              labelKey: 'send_adjustment',
              isLoading: isLoading,
              onTap: isLoading ? null : onSubmit,
            ),
          ),
        ],
      ),
    );
  }
}

/// بوتوم شيت اختيار صنف من أصناف المغسلة
/// بيرجّع الصنف اللي اتختار، أو null لو اتقفل من غير اختيار
class _ServiceItemPicker extends StatelessWidget {
  final MyServicesCubit cubit;

  const _ServiceItemPicker({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // المقبض الرمادي الصغير فوق
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.semiWhiteColor2,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Gap(18.h),
          LocalizedLabel(
            text: 'choose_service_item',
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18, weight: FontWeight.w800),
          ),
          Gap(14.h),
          Flexible(
            child: BlocBuilder<MyServicesCubit, BaseState<MyServiceItem>>(
              bloc: cubit,
              builder: (context, state) {
                if (state.items.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: state.isLoading || state.isInitial
                          ? const CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            )
                          : LocalizedLabel(
                              text: state.isFailure
                                  ? 'services_load_failed'
                                  : 'no_service_items',
                              style: TextStyles.darkRegular14.copyWith(
                                color: AppColors.greyColor3,
                              ),
                            ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.12),
                  ),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () => Navigator.of(context).pop(item),
                      title: Label(
                        text: item.serviceItemName,
                        style: TextStyles.darkBold14,
                      ),
                      subtitle: Label(
                        text: item.serviceName,
                        style: TextStyles.darkRegular12.copyWith(
                          color: AppColors.greyColor4,
                        ),
                      ),
                      trailing: Label(
                        text: formatAmount(item.price),
                        style: TextStyles.darkBold14.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
