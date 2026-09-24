import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/common_widget/loading_button.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/services/data/laundry_services_data_source.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/delete_services_dialog.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/edit_service_price_sheet.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/service_card.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/services_skeleton.dart';
import 'package:lavanderia_partner/features/services/presentation/view_model/services_cubits.dart';

/// صفحة خدمات المغسلة: الأصناف بأسعارها متجمعة تحت كل خدمة
/// تعديل السعر بيفضل محلي لحد ما اليوزر يضغط حفظ (PUT)
/// والضغط المطوّل على صنف بيفتح وضع التحديد للحذف (DELETE)
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = getIt<LaundryServicesDataSource>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MyServicesCubit(dataSource)..fetchData()),
        BlocProvider(create: (_) => UpdateMyServicesCubit(dataSource)),
        BlocProvider(create: (_) => DeleteMyServicesCubit(dataSource)),
      ],
      child: const _ServicesView(),
    );
  }
}

class _ServicesView extends StatefulWidget {
  const _ServicesView();

  @override
  State<_ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<_ServicesView> {
  /// الأسعار اللي اتعدّلت ولسه متبعتتش، بالـ serviceItemId
  final Map<int, double> _editedPrices = {};

  /// الأصناف المحددة للحذف بالـ serviceItemId
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  double _priceOf(MyServiceItem item) =>
      _editedPrices[item.serviceItemId] ?? item.price;

  Future<void> _editPrice(MyServiceItem item) async {
    final price = await showEditServicePriceSheet(
      context: context,
      item: item,
      currentPrice: _priceOf(item),
    );
    if (price == null || !mounted) return;

    setState(() {
      // لو رجع للسعر الأصلي يبقى مفيش تعديل أصلاً
      if (price == item.price) {
        _editedPrices.remove(item.serviceItemId);
      } else {
        _editedPrices[item.serviceItemId] = price;
      }
    });
  }

  void _save() {
    context.read<UpdateMyServicesCubit>().submit([
      for (final entry in _editedPrices.entries)
        ServiceItemPrice(serviceItemId: entry.key, price: entry.value),
    ]);
  }

  void _startSelection(MyServiceItem item) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(item.serviceItemId);
    });
  }

  void _toggleSelection(int serviceItemId) {
    setState(() {
      if (!_selectedIds.remove(serviceItemId)) _selectedIds.add(serviceItemId);
    });
  }

  /// لو كل أصناف الخدمة متحددة بيلغيها، غير كده بيحددها كلها
  void _toggleGroup(List<MyServiceItem> items) {
    final ids = items.map((item) => item.serviceItemId);
    setState(() {
      if (ids.every(_selectedIds.contains)) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDeleteServicesDialog(
      context,
      _selectedIds.length,
    );
    if (confirmed != true || !mounted) return;

    context.read<DeleteMyServicesCubit>().submit(_selectedIds.toList());
  }

  void _onUpdateStateChanged(
    BuildContext context,
    BaseState<List<ServiceItemPrice>> state,
  ) {
    if (state.isSuccess) {
      context.read<MyServicesCubit>().applyPrices(state.data ?? []);
      setState(_editedPrices.clear);
      context.showSuccessMessage('services_saved'.tr());
      return;
    }
    _showServerError(context, state.isFailure, state.failure);
  }

  void _onDeleteStateChanged(BuildContext context, BaseState<List<int>> state) {
    if (state.isSuccess) {
      final deletedIds = state.data ?? [];
      context.read<MyServicesCubit>().removeItems(deletedIds);
      // التعديلات بتاعة الأصناف اللي اتحذفت ملهاش لازمة
      _editedPrices.removeWhere((id, _) => deletedIds.contains(id));
      _exitSelection();
      context.showSuccessMessage('services_deleted'.tr());
      return;
    }
    _showServerError(context, state.isFailure, state.failure);
  }

  /// أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
  void _showServerError(
    BuildContext context,
    bool isFailure,
    Failure? failure,
  ) {
    if (isFailure && (failure is ServerFailure || failure is UnknownFailure)) {
      context.showErrorMessage(failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UpdateMyServicesCubit, BaseState<List<ServiceItemPrice>>>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onUpdateStateChanged,
        ),
        BlocListener<DeleteMyServicesCubit, BaseState<List<int>>>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onDeleteStateChanged,
        ),
      ],
      // زرار الرجوع بيقفل وضع التحديد الأول قبل ما يخرج من الصفحة
      child: PopScope(
        canPop: !_isSelectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exitSelection();
        },
        child: Scaffold(
          backgroundColor: AppColors.semiWhiteColor3,
          body: BlocBuilder<MyServicesCubit, BaseState<MyServiceItem>>(
            builder: (context, state) => Column(
              children: [
                _isSelectionMode
                    ? _SelectionHeader(
                        selectedCount: _selectedIds.length,
                        onClose: _exitSelection,
                        onDelete: _deleteSelected,
                      )
                    : _ServicesHeader(itemsCount: state.items.length),
                Expanded(child: _buildBody(context, state)),
                // شريط الحفظ بيظهر بس لما يكون فيه تعديلات، ومش في وضع التحديد
                if (_editedPrices.isNotEmpty && !_isSelectionMode)
                  BlocBuilder<
                    UpdateMyServicesCubit,
                    BaseState<List<ServiceItemPrice>>
                  >(
                    builder: (context, updateState) => _SaveBar(
                      isSaving: updateState.isLoading,
                      onSave: _save,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BaseState<MyServiceItem> state) {
    final cubit = context.read<MyServicesCubit>();
    if (state.isFailure && state.items.isEmpty) {
      return _RetryMessage(onRetry: cubit.fetchData);
    }
    if (!state.isSuccess) {
      return const ServicesSkeleton();
    }

    final groups = _groupByService(state.items);
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.fetchData,
      child: groups.isEmpty
          ? ListView(
              // لازم يبقى scrollable عشان السحب للتحديث يشتغل
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Gap(120.h),
                LocalizedLabel(
                  text: 'no_my_services',
                  textAlign: TextAlign.center,
                  style: TextStyles.darkRegular14.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              itemCount: groups.length,
              itemBuilder: (context, index) => _buildGroup(groups[index]),
            ),
    );
  }

  Widget _buildGroup(_ServiceGroup group) {
    final allSelected = group.items.every(
      (item) => _selectedIds.contains(item.serviceItemId),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GroupHeader(
            name: group.serviceName,
            count: group.items.length,
            isSelectionMode: _isSelectionMode,
            allSelected: allSelected,
            onToggleAll: () => _toggleGroup(group.items),
          ),
          Gap(10.h),
          for (final item in group.items) ...[
            ServiceCard(
              key: ValueKey(item.serviceItemId),
              item: item,
              price: _priceOf(item),
              isEdited: _editedPrices.containsKey(item.serviceItemId),
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedIds.contains(item.serviceItemId),
              onEdit: () => _editPrice(item),
              onTap: _isSelectionMode
                  ? () => _toggleSelection(item.serviceItemId)
                  : () => _editPrice(item),
              onLongPress: () => _isSelectionMode
                  ? _toggleSelection(item.serviceItemId)
                  : _startSelection(item),
            ),
            Gap(10.h),
          ],
        ],
      ),
    );
  }

  /// الريسبونس لستة واحدة، فبنجمّعها بالخدمة بنفس ترتيب أول ظهور ليها
  List<_ServiceGroup> _groupByService(List<MyServiceItem> items) {
    final groups = <int, _ServiceGroup>{};
    for (final item in items) {
      groups
          .putIfAbsent(
            item.serviceId,
            () => _ServiceGroup(serviceName: item.serviceName),
          )
          .items
          .add(item);
    }
    return groups.values.toList();
  }
}

class _ServiceGroup {
  final String serviceName;
  final List<MyServiceItem> items = [];

  _ServiceGroup({required this.serviceName});
}

/// الهيدر الأزرق: عنوان الصفحة وتحته عدد الأصناف
class _ServicesHeader extends StatelessWidget {
  final int itemsCount;

  const _ServicesHeader({required this.itemsCount});

  @override
  Widget build(BuildContext context) {
    return _HeaderContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedLabel(
            text: 'services',
            style: TextStyles.whiteText(22, weight: FontWeight.w800),
          ),
          Gap(4.h),
          Label(
            text: 'service_items_count'.tr(args: [itemsCount.toString()]),
            style: TextStyles.whiteText(
              13,
              weight: FontWeight.w400,
            ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// الهيدر في وضع التحديد: قفل وعدد المحدد وزرار الحذف
class _SelectionHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onDelete;

  const _SelectionHeader({
    required this.selectedCount,
    required this.onClose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderContainer(
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.whiteColor),
          ),
          Gap(4.w),
          Expanded(
            child: Label(
              text: 'selected_count'.tr(args: [selectedCount.toString()]),
              style: TextStyles.whiteText(18, weight: FontWeight.w800),
            ),
          ),
          BlocBuilder<DeleteMyServicesCubit, BaseState<List<int>>>(
            builder: (context, state) => state.isLoading
                ? const LoadingButton(color: AppColors.whiteColor)
                : IconButton(
                    onPressed: selectedCount == 0 ? null : onDelete,
                    tooltip: 'delete'.tr(),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: selectedCount == 0
                          ? Colors.white.withValues(alpha: 0.4)
                          : AppColors.whiteColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderContainer extends StatelessWidget {
  final Widget child;

  const _HeaderContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20.w,
        MediaQuery.of(context).padding.top + 16.h,
        20.w,
        20.h,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
      ),
      child: child,
    );
  }
}

/// اسم الخدمة فوق أصنافها، وفي وضع التحديد بيبقى فيه زرار تحديد الكل
class _GroupHeader extends StatelessWidget {
  final String name;
  final int count;
  final bool isSelectionMode;
  final bool allSelected;
  final VoidCallback onToggleAll;

  const _GroupHeader({
    required this.name,
    required this.count,
    required this.isSelectionMode,
    required this.allSelected,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Label(
            text: '$name ($count)',
            maxLines: 1,
            style: TextStyles.boldStyle(16, weight: FontWeight.w800),
          ),
        ),
        if (isSelectionMode)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleAll,
            child: LocalizedLabel(
              text: allSelected ? 'deselect_all' : 'select_all',
              style: TextStyles.boldStyle(
                13,
                color: AppColors.primaryColor,
                weight: FontWeight.w700,
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
            text: 'services_load_failed',
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

/// شريط الحفظ اللي بيطلع من تحت لما يكون فيه تعديلات متحفظتش
class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveBar({required this.isSaving, required this.onSave});

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
          // بنقفل الضغط وقت الحفظ عشان مايتبعتش مرتين
          onPressed: isSaving ? () {} : onSave,
          title: isSaving ? 'saving' : 'save_changes',
          backgroundColor: isSaving
              ? AppColors.primaryColor.withValues(alpha: 0.6)
              : AppColors.primaryColor,
        ),
      ),
    );
  }
}
