import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/router/bottom_nav_controller.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_timeline.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/update_status_sheet.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/order_action_cubit.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';

/// صفحة تفاصيل الطلب
/// أي تعديل بيتبعت لـ [OrdersCubit.notifyChanged] عشان كل الليستات تحدّث نفسها
class OrderDetailsScreen extends StatefulWidget {
  final PartnerOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late PartnerOrder _order = widget.order;

  final OrderActionCubit _actionCubit = OrderActionCubit(
    getIt<OrdersDataSource>(),
  );

  @override
  void dispose() {
    _actionCubit.close();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    final newStage = await showUpdateStatusSheet(
      context: context,
      currentStage: _order.stage,
    );
    if (newStage == null || !mounted) return;

    setState(() => _order = _order.copyWithStage(newStage));
    OrdersCubit.notifyChanged(_order);
  }

  /// المقبول بيروح لطلباتي، والمرفوض الليستات بتشيله لوحدها
  void _onActionStateChanged(
    BuildContext context,
    BaseState<PartnerOrder> state,
  ) {
    if (state.isSuccess) {
      final accepted = _actionCubit.pendingAction == OrderAction.accept;
      Navigator.of(context).pop();
      if (accepted) BottomNavController.instance.goTo(BottomNavTab.orders);
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
    // آخر مرحلة يبقى مفيش حاجة نحدّثها بعدها
    final canUpdate = _order.stage.next != null;
    final isNew = _order.status == PartnerOrderStatus.newOrder;

    return BlocListener<OrderActionCubit, BaseState<PartnerOrder>>(
      bloc: _actionCubit,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onActionStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.semiWhiteColor3,
        body: Column(
          children: [
            _DetailsHeader(order: _order),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  children: [
                    CustomerInfoCard(order: _order),
                    Gap(14.h),
                    OrderItemsCard(order: _order),
                    Gap(14.h),
                    OrderMetaCard(order: _order),
                    Gap(14.h),
                    DetailsCard(
                      titleKey: 'order_stages',
                      child: OrderTimeline(currentStage: _order.stage),
                    ),
                    Gap(20.h),
                    // الطلب الجديد لازم يتقبل الأول قبل ما حالته تتحدث
                    if (isNew)
                      BlocBuilder<OrderActionCubit, BaseState<PartnerOrder>>(
                        bloc: _actionCubit,
                        builder: (context, state) => _AcceptRejectBar(
                          loadingAction: state.isLoading
                              ? _actionCubit.pendingAction
                              : null,
                          onAccept: () => _actionCubit.accept(_order),
                          onReject: () => _actionCubit.reject(_order),
                        ),
                      )
                    else if (canUpdate)
                      CustomButton(
                        title: 'update_status',
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        onPressed: _updateStatus,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زراير قبول ورفض الطلب الجديد
/// وهو بيحمّل الزرار اللي اتداس بيبقى لودينج والاتنين بيتقفلوا
class _AcceptRejectBar extends StatelessWidget {
  final OrderAction? loadingAction;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _AcceptRejectBar({
    required this.loadingAction,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isBusy = loadingAction != null;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            labelKey: 'accept_order',
            background: AppColors.primaryColor,
            foreground: AppColors.whiteColor,
            isLoading: loadingAction == OrderAction.accept,
            onTap: isBusy ? null : onAccept,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: _ActionButton(
            labelKey: 'reject_order',
            background: AppColors.redColor2.withValues(alpha: 0.1),
            foreground: AppColors.redColor2,
            isLoading: loadingAction == OrderAction.reject,
            onTap: isBusy ? null : onReject,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String labelKey;
  final Color background;
  final Color foreground;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.labelKey,
    required this.background,
    required this.foreground,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: foreground,
                ),
              )
            : LocalizedLabel(
                text: labelKey,
                style: TextStyles.boldStyle(
                  16,
                  color: foreground,
                  weight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// الهيدر الأزرق: رقم الطلب وشيب الحالة وزرار الرجوع
class _DetailsHeader extends StatelessWidget {
  final PartnerOrder order;

  const _DetailsHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16.w,
        MediaQuery.of(context).padding.top + 12.h,
        16.w,
        18.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // زرار الرجوع، السهم بيشاور ناحية الرجوع حسب اتجاه اللغة
          // في العربي على اليمين وفي الإنجليزي على الشمال
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Directionality.of(context) == TextDirection.ltr
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.arrow_back_ios_new_rounded,
                size: 15.sp,
                color: AppColors.whiteColor,
              ),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Label(
                  text: order.displayNumber,
                  maxLines: 1,
                  style: TextStyles.whiteText(19, weight: FontWeight.w800),
                ),
                // Gap(8.h),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: order.status.backgroundColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: LocalizedLabel(
                    text: order.status.labelKey,
                    maxLines: 1,
                    style: TextStyles.boldStyle(
                      12,
                      color: order.status.foregroundColor,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
