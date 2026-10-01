import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/order_details_screen.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_actions_panel.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/order_action_cubit.dart';

/// بوب أب الطلب الجديد اللي بيظهر لحظياً مع OrderCreated
/// المغسلة تقدر تقبل أو ترفض من هنا، أو تفتح التفاصيل الأول
Future<void> showNewOrderDialog(BuildContext context, PartnerOrder order) {
  return showDialog<void>(
    context: context,
    builder: (_) => _NewOrderDialog(order: order),
  );
}

class _NewOrderDialog extends StatefulWidget {
  final PartnerOrder order;

  const _NewOrderDialog({required this.order});

  @override
  State<_NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<_NewOrderDialog> {
  final OrderActionCubit _actionCubit = OrderActionCubit(
    getIt<OrdersDataSource>(),
  );

  @override
  void dispose() {
    _actionCubit.close();
    super.dispose();
  }

  void _onActionStateChanged(
    BuildContext context,
    BaseState<PartnerOrder> state,
  ) {
    final navigator = Navigator.of(context);
    if (state.isSuccess) {
      final messageKey = _actionCubit.pendingAction == OrderAction.accept
          ? 'new_order_accepted'
          : 'new_order_rejected';
      navigator.pop();
      navigator.context.showSuccessMessage(messageKey.tr());
      return;
    }
    // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
    final failure = state.failure;
    if (state.isFailure &&
        (failure is ServerFailure || failure is UnknownFailure)) {
      context.showErrorMessage(failure!.message);
    }
  }

  void _openDetails() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(order: widget.order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return BlocConsumer<OrderActionCubit, BaseState<PartnerOrder>>(
      bloc: _actionCubit,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onActionStateChanged,
      builder: (context, state) {
        final loadingAction = state.isLoading
            ? _actionCubit.pendingAction
            : null;
        final isBusy = loadingAction != null;

        return AlertDialog(
          backgroundColor: AppColors.whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          contentPadding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_laundry_service_outlined,
                  size: 26.sp,
                  color: AppColors.primaryColor,
                ),
              ),
              Gap(16.h),
              LocalizedLabel(
                text: 'new_order_received',
                textAlign: TextAlign.center,
                style: TextStyles.boldStyle(18, weight: FontWeight.w800),
              ),
              Gap(8.h),
              Label(
                text: '${order.displayNumber}  ${order.customerName}',
                textAlign: TextAlign.center,
                style: TextStyles.darkRegular14.copyWith(
                  color: AppColors.greyColor3,
                ),
              ),
              Gap(4.h),
              Label(
                text:
                    '${'new_order_pieces'.tr(args: ['${order.itemsCount}'])}'
                    ' • ${order.displayTotal}',
                textAlign: TextAlign.center,
                style: TextStyles.boldStyle(15, weight: FontWeight.w700),
              ),
              Gap(20.h),
              Row(
                children: [
                  Expanded(
                    child: OrderActionButton(
                      labelKey: 'accept_order',
                      isLoading: loadingAction == OrderAction.accept,
                      onTap: isBusy ? null : () => _actionCubit.accept(order),
                    ),
                  ),
                  Gap(10.w),
                  Expanded(
                    child: OrderActionButton(
                      labelKey: 'reject_order',
                      isPrimary: false,
                      foreground: AppColors.redColor2,
                      isLoading: loadingAction == OrderAction.reject,
                      onTap: isBusy ? null : () => _actionCubit.reject(order),
                    ),
                  ),
                ],
              ),
              Gap(6.h),
              TextButton(
                onPressed: isBusy ? null : _openDetails,
                child: LocalizedLabel(
                  text: 'view_details',
                  style: TextStyles.boldStyle(
                    14,
                    color: AppColors.primaryColor,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
