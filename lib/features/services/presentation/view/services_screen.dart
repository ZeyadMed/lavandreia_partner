import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';
import 'package:lavanderia_partner/features/services/data/laundry_services_data_source.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';
import 'package:lavanderia_partner/features/services/presentation/view/add_services_screen.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/delete_services_dialog.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/edit_service_price_sheet.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/service_card.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/services_skeleton.dart';
import 'package:lavanderia_partner/features/services/presentation/view/widgets/swipe_to_delete.dart';
import 'package:lavanderia_partner/features/services/presentation/view_model/services_cubits.dart';

/// صفحة خدمات المغسلة: الأصناف بأسعارها متجمعة تحت كل خدمة
/// تعديل السعر بيفضل محلي لحد ما اليوزر يضغط حفظ (PUT)
/// سحب الصنف بيكشف زرار حذفه، وزرار التحديد أو الضغط المطوّل بيفتح
/// وضع التحديد لحذف كذا صنف مع بعض (DELETE)، والاتنين بتأكيد الأول
/// وزرار الإضافة بيفتح الخدمات المتاحة لإضافة أصناف جديدة
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
  static const _typesBannerDismissedKey = 'item_types_banner_dismissed';

  /// الأسعار اللي اتعدّلت ولسه متبعتتش، بالـ serviceItemId
  final Map<int, double> _editedPrices = {};

  /// الأصناف المحددة للحذف بالـ serviceItemId
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  /// الصنف اللي مسحوب وزرار حذفه ظاهر، عشان صنف واحد بس يفضل مفتوح
  final _openSwipeId = ValueNotifier<Object?>(null);

  /// تنبيه تسعير الأنواع، بيختفي للأبد لما المغسلة تقفله
  late bool _showTypesBanner =
      CacheManager.sharedPreferences.getBool(_typesBannerDismissedKey) != true;

  void _dismissTypesBanner() {
    setState(() => _showTypesBanner = false);
    CacheManager.sharedPreferences.setBool(_typesBannerDismissedKey, true);
  }

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

  /// التعديلات اللي لسه متحفظتش بتفضل زي ما هي بعد ما اللستة تتجاب تاني
  Future<void> _addServices(List<MyServiceItem> myItems) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddServicesScreen(
          addedItemIds: {for (final item in myItems) item.serviceItemId},
        ),
      ),
    );
    if (added != true || !mounted) return;

    context.read<MyServicesCubit>().fetchData();
    context.showSuccessMessage('services_added'.tr());
  }

  @override
  void dispose() {
    _openSwipeId.dispose();
    super.dispose();
  }

  /// من زرار التحديد من غير صنف، أو من الضغط المطوّل على صنف
  void _startSelection([MyServiceItem? item]) {
    _openSwipeId.value = null;
    setState(() {
      _isSelectionMode = true;
      if (item != null) _selectedIds.add(item.serviceItemId);
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

  void _deleteSelected() {
    _confirmAndDelete([
      for (final item in context.read<MyServicesCubit>().state.items)
        if (_selectedIds.contains(item.serviceItemId)) item,
    ]);
  }

  /// مفيش حذف من غير ما اليوزر يأكّد الأول
  Future<void> _confirmAndDelete(List<MyServiceItem> items) async {
    if (items.isEmpty) return;
    final confirmed = await showDeleteServicesDialog(context, items);
    if (confirmed != true || !mounted) return;

    context.read<DeleteMyServicesCubit>().submit([
      for (final item in items) item.serviceItemId,
    ]);
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
      context.showSuccessMessage('services_deleted'.plural(deletedIds.length));
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
          body: BlocBuilder<MyServicesCubit, BaseState<MyServiceItem>>(
            builder: (context, state) => Column(
              children: [
                _isSelectionMode
                    ? _SelectionHeader(
                        selectedCount: _selectedIds.length,
                        onClose: _exitSelection,
                      )
                    : _ServicesHeader(
                        itemsCount: state.items.length,
                        onSelect: state.items.isNotEmpty
                            ? _startSelection
                            : null,
                        // لازم اللستة تكون اتجابت الأول، عشان الأصناف الموجودة تظهر "مضاف"
                        onAdd: state.isSuccess
                            ? () => _addServices(state.items)
                            : null,
                      ),
                Expanded(child: _buildBody(context, state)),
                // زرار الحذف الجماعي تحت وظاهر طول ما وضع التحديد مفتوح
                if (_isSelectionMode)
                  _DeleteBar(
                    selectedCount: _selectedIds.length,
                    onDelete: _deleteSelected,
                  )
                // شريط الحفظ بيظهر بس لما يكون فيه تعديلات، ومش في وضع التحديد
                else if (_editedPrices.isNotEmpty)
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

    final groups = groupByService(state.items);
    final leading = [
      // الأصناف اللي بقى ليها أنواع أسعارها القديمة اتمسحت، فاللستة ممكن تكون ناقصة
      if (_showTypesBanner && !_isSelectionMode)
        _ItemTypesBanner(
          onAdd: () => _addServices(state.items),
          onDismiss: _dismissTypesBanner,
        ),
      if (!_isSelectionMode) const _SwipeHint(),
    ];
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: cubit.fetchData,
      child: groups.isEmpty
          ? ListView(
              // لازم يبقى scrollable عشان السحب للتحديث يشتغل
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              children: [
                Gap(120.h),
                LocalizedLabel(
                  text: 'no_my_services',
                  textAlign: TextAlign.center,
                  style: TextStyles.darkRegular14.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
                Gap(6.h),
                LocalizedLabel(
                  text: 'price_item_types_hint',
                  textAlign: TextAlign.center,
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
                Gap(8.h),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _addServices(state.items),
                    icon: const Icon(
                      Icons.add_rounded,
                      color: AppColors.primaryColor,
                    ),
                    label: LocalizedLabel(
                      text: 'add_service',
                      style: TextStyles.darkBold14.copyWith(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            )
          // أول ما اللستة تتحرك الصنف المسحوب بيتقفل
          : NotificationListener<ScrollStartNotification>(
              onNotification: (_) {
                _openSwipeId.value = null;
                return false;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                itemCount: leading.length + groups.length,
                itemBuilder: (context, index) => index < leading.length
                    ? leading[index]
                    : _buildGroup(groups[index - leading.length]),
              ),
            ),
    );
  }

  Widget _buildGroup(MyServiceGroup group) {
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
          // الأنواع بتظهر تحت اسم الصنف الأب، والصنف اللي ملوش أنواع لوحده
          for (final itemGroup in groupByParent(group.items))
            if (itemGroup.parentName == null)
              for (final item in itemGroup.items) _buildCard(item)
            else ...[
              _ParentItemHeader(name: itemGroup.parentName!),
              Gap(8.h),
              for (final item in itemGroup.items)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 14.w),
                  child: _buildCard(item),
                ),
            ],
        ],
      ),
    );
  }

  Widget _buildCard(MyServiceItem item) {
    return Padding(
      key: ValueKey(item.serviceItemId),
      padding: EdgeInsets.only(bottom: 10.h),
      // الصنف اللي بيتحذف بيبهت لحد ما الريكوست يخلص
      child: BlocSelector<DeleteMyServicesCubit, BaseState<List<int>>, bool>(
        selector: (state) =>
            state.isLoading &&
            (state.data?.contains(item.serviceItemId) ?? false),
        builder: (context, isDeleting) => IgnorePointer(
          ignoring: isDeleting,
          child: AnimatedOpacity(
            opacity: isDeleting ? 0.4 : 1,
            duration: const Duration(milliseconds: 150),
            child: SwipeToDelete(
              id: item.serviceItemId,
              openId: _openSwipeId,
              enabled: !_isSelectionMode,
              onDelete: () => _confirmAndDelete([item]),
              child: ServiceCard(
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
            ),
          ),
        ),
      ),
    );
  }
}

/// الهيدر الأزرق: عنوان الصفحة وتحته عدد الأصناف، وجنبه زرارين التحديد والإضافة
class _ServicesHeader extends StatelessWidget {
  final int itemsCount;

  /// null لو مفيش أصناف تتحدد
  final VoidCallback? onSelect;

  /// null لحد ما أصناف المغسلة تتجاب
  final VoidCallback? onAdd;

  const _ServicesHeader({
    required this.itemsCount,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderContainer(
      child: Row(
        children: [
          Expanded(
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
          ),
          Gap(12.w),
          _HeaderButton(
            icon: Icons.checklist_rounded,
            labelKey: 'select',
            onTap: onSelect,
          ),
          Gap(8.w),
          _HeaderButton(
            icon: Icons.add_rounded,
            labelKey: 'add_service',
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

/// زرار أبيض شفاف في الهيدر، بيبهت لما يكون مقفول
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String labelKey;
  final VoidCallback? onTap;

  const _HeaderButton({
    required this.icon,
    required this.labelKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18.sp, color: AppColors.whiteColor),
                Gap(4.w),
                LocalizedLabel(
                  text: labelKey,
                  style: TextStyles.whiteText(13, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// الهيدر في وضع التحديد: قفل وعدد المحدد، وزرار الحذف في الشريط اللي تحت
class _SelectionHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;

  const _SelectionHeader({required this.selectedCount, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return _HeaderContainer(
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            tooltip: 'cancel'.tr(),
            icon: const Icon(Icons.close, color: AppColors.whiteColor),
          ),
          Gap(4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Label(
                  text: 'selected_count'.tr(args: [selectedCount.toString()]),
                  style: TextStyles.whiteText(18, weight: FontWeight.w800),
                ),
                LocalizedLabel(
                  text: 'tap_items_to_select',
                  maxLines: 1,
                  style: TextStyles.whiteText(
                    13,
                    weight: FontWeight.w400,
                  ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
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

/// سطر صغير فوق الأصناف بيعرّف المغسلة إن السحب بيكشف زرار الحذف
class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          Icon(Icons.swipe_rounded, size: 18.sp, color: AppColors.greyColor3),
          Gap(6.w),
          Expanded(
            child: LocalizedLabel(
              text: 'swipe_to_delete_hint',
              maxLines: 2,
              style: TextStyles.darkRegular12.copyWith(
                color: AppColors.greyColor3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// اسم الصنف الأب فوق أنواعه، زي "قميص" فوق "قميص كتان"
class _ParentItemHeader extends StatelessWidget {
  final String name;

  const _ParentItemHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Label(
      text: name,
      maxLines: 1,
      style: TextStyles.darkBold14.copyWith(color: AppColors.greyColor3),
    );
  }
}

/// تنبيه إن بعض الأصناف بقى ليها أنواع وأسعارها القديمة اتمسحت
/// بيوجّه المغسلة تسعّر الأنواع من صفحة الإضافة
class _ItemTypesBanner extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  const _ItemTypesBanner({required this.onAdd, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsetsDirectional.fromSTEB(14.w, 12.h, 4.w, 4.h),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20.sp,
                color: AppColors.primaryColor,
              ),
              Gap(8.w),
              Expanded(
                child: LocalizedLabel(
                  text: 'price_item_types_hint',
                  style: TextStyles.darkRegular14,
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                tooltip: 'close'.tr(),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18.sp, color: Colors.grey),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryColor),
            label: LocalizedLabel(
              text: 'add_service',
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
    return _BottomBar(
      child: CustomButton(
        // بنقفل الضغط وقت الحفظ عشان مايتبعتش مرتين
        onPressed: isSaving ? () {} : onSave,
        title: isSaving ? 'saving' : 'save_changes',
        backgroundColor: isSaving
            ? AppColors.primaryColor.withValues(alpha: 0.6)
            : AppColors.primaryColor,
      ),
    );
  }
}

/// شريط الحذف الجماعي في وضع التحديد، بيبهت لحد ما يتحدد صنف
class _DeleteBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;

  const _DeleteBar({required this.selectedCount, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeleteMyServicesCubit, BaseState<List<int>>>(
      builder: (context, state) {
        final isDeleting = state.isLoading;
        final enabled = selectedCount > 0 && !isDeleting;
        return _BottomBar(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Material(
              color: enabled
                  ? AppColors.redColor2
                  : AppColors.redColor2.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                onTap: enabled ? onDelete : null,
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDeleting)
                        SizedBox.square(
                          dimension: 18.sp,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.whiteColor,
                          ),
                        )
                      else
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20.sp,
                          color: AppColors.whiteColor,
                        ),
                      Gap(8.w),
                      Label(
                        text: isDeleting
                            ? 'deleting'.tr()
                            : 'delete_selected_count'.tr(
                                args: [selectedCount.toString()],
                              ),
                        maxLines: 1,
                        style: TextStyles.whiteText(
                          16,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// الشريط الأبيض اللي تحت الصفحة، للحفظ أو للحذف الجماعي
class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

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
      child: SafeArea(top: false, child: child),
    );
  }
}
