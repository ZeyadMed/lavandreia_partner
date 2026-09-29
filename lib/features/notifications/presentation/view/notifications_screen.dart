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
import 'package:lavanderia_partner/features/notifications/data/models/partner_notification.dart';
import 'package:lavanderia_partner/features/notifications/data/notifications_data_source.dart';
import 'package:lavanderia_partner/features/notifications/presentation/view/widgets/clear_notifications_dialog.dart';
import 'package:lavanderia_partner/features/notifications/presentation/view_model/notifications_cubit.dart';

/// صفحة الإشعارات: صفحة ورا صفحة مع السكرول، والسحب لتحت بيحدثها
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsCubit _cubit =
      NotificationsCubit(getIt<NotificationsDataSource>())
        ..initPagination()
        ..fetch(page: 1);

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _showFailure(Failure? failure) {
    if (failure != null && mounted) context.showErrorMessage(failure.message);
  }

  Future<void> _markAsRead(PartnerNotification notification) async =>
      _showFailure(await _cubit.markAsRead(notification));

  Future<void> _delete(PartnerNotification notification) async =>
      _showFailure(await _cubit.delete(notification));

  Future<void> _onMenuSelected(_MenuAction action) async {
    switch (action) {
      case _MenuAction.readAll:
        _showFailure(await _cubit.markAllAsRead());
      case _MenuAction.deleteAll:
        final confirmed = await showClearNotificationsDialog(context);
        if (confirmed == true) _showFailure(await _cubit.deleteAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      appBar: CustomAppBar(
        title: 'notifications',
        actions: [
          BlocBuilder<NotificationsCubit, BaseState<PartnerNotification>>(
            bloc: _cubit,
            builder: (context, state) => state.items.isEmpty
                ? const SizedBox.shrink()
                : _NotificationsMenu(
                    hasUnread: _cubit.hasUnread,
                    onSelected: _onMenuSelected,
                  ),
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, BaseState<PartnerNotification>>(
        bloc: _cubit,
        builder: (context, state) => RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: _cubit.refresh,
          child: ListView(
            controller: _cubit.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: _buildNotifications(state),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNotifications(BaseState<PartnerNotification> state) {
    // السحب للتحديث بيرجع لـ loading، فبنسيب اللستة القديمة ظاهرة لحد ما الجديدة توصل
    if (state.items.isEmpty) {
      if (state.isFailure) {
        return [
          _CenteredMessage(
            text: 'notifications_load_failed',
            color: AppColors.redColor,
            onRetry: _cubit.refresh,
          ),
        ];
      }
      if (state.isSuccess) {
        return const [
          _CenteredMessage(
            text: 'no_notifications',
            color: AppColors.greyColor3,
            icon: Icons.notifications_off_outlined,
          ),
        ];
      }
      return List.generate(
        6,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: const _NotificationCardSkeleton(),
        ),
      );
    }

    return [
      for (final notification in state.items)
        Padding(
          key: ValueKey(notification.id),
          padding: EdgeInsets.only(bottom: 10.h),
          child: Dismissible(
            key: ValueKey(notification.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            onDismissed: (_) => _delete(notification),
            child: _NotificationCard(
              notification: notification,
              onTap: () => _markAsRead(notification),
            ),
          ),
        ),
      _ListFooter(
        state: state,
        onRetry: () => _cubit.fetch(page: state.page),
      ),
    ];
  }
}

enum _MenuAction { readAll, deleteAll }

/// قايمة الأبار: تعليم الكل كمقروء (لو فيه غير مقروء) ومسح الكل
class _NotificationsMenu extends StatelessWidget {
  final bool hasUnread;
  final ValueChanged<_MenuAction> onSelected;

  const _NotificationsMenu({required this.hasUnread, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      icon: const Icon(Icons.more_vert, color: AppColors.darkTextColor),
      color: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (hasUnread)
          _menuItem(
            _MenuAction.readAll,
            Icons.done_all_rounded,
            'mark_all_as_read',
            AppColors.darkTextColor,
          ),
        _menuItem(
          _MenuAction.deleteAll,
          Icons.delete_sweep_outlined,
          'delete_all_notifications',
          AppColors.redColor2,
        ),
      ],
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction value,
    IconData icon,
    String labelKey,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: color),
          Gap(10.w),
          LocalizedLabel(
            text: labelKey,
            style: TextStyles.darkRegular14.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// الخلفية الحمرا اللي بتظهر وانت بتسحب الإشعار عشان تمسحه
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(end: 20.w),
      decoration: BoxDecoration(
        color: AppColors.redColor2,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        size: 24.sp,
        color: AppColors.whiteColor,
      ),
    );
  }
}

/// كارت إشعار واحد، ولو مش مقروء بيبقى بخلفية زرقا فاتحة ونقطة جنب العنوان
/// الضغط عليه بيعلّمه كمقروء
class _NotificationCard extends StatelessWidget {
  final PartnerNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final createdAt = notification.createdAt;
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? AppColors.secondaryColor : AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(
          color: isUnread
              ? AppColors.primaryColor.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.25),
          width: 0.9,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: _buildContent(context, createdAt, isUnread),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DateTime? createdAt,
    bool isUnread,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.icon,
            size: 20.sp,
            color: AppColors.primaryColor,
          ),
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyles.darkBold14,
                    ),
                  ),
                  if (isUnread) ...[
                    Gap(8.w),
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              if (notification.body.isNotEmpty) ...[
                Gap(6.h),
                Text(
                  notification.body,
                  style: TextStyles.darkRegular14.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
              ],
              if (createdAt != null) ...[
                Gap(8.h),
                Text(
                  DateFormat(
                    'd MMM yyyy - h:mm a',
                    context.locale.toString(),
                  ).format(createdAt),
                  style: TextStyles.darkRegular12.copyWith(
                    color: AppColors.greyColor3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// آخر اللستة: لودينج الصفحة الجاية أو زرار إعادة المحاولة لو فشلت
class _ListFooter extends StatelessWidget {
  final BaseState<PartnerNotification> state;
  final VoidCallback onRetry;

  const _ListFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }
    if (state.isLoadingMoreFauilare) {
      return Center(child: _RetryButton(onRetry: onRetry));
    }
    return const SizedBox.shrink();
  }
}

/// رسالة في نص الصفحة للفشل أو اللستة الفاضية
class _CenteredMessage extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback? onRetry;

  const _CenteredMessage({
    required this.text,
    required this.color,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80.h),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 56.sp, color: AppColors.greyColor5),
            Gap(8.h),
          ],
          LocalizedLabel(
            text: text,
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(color: color),
          ),
          if (onRetry != null) _RetryButton(onRetry: onRetry!),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
      label: LocalizedLabel(
        text: 'try_again',
        style: TextStyles.darkBold14.copyWith(color: AppColors.primaryColor),
      ),
    );
  }
}

/// لودينج أول صفحة بنفس شكل [_NotificationCard]
class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.25),
          width: 0.9,
        ),
      ),
      child: SkeletonShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 40.r, height: 40.r, radius: 20.r),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140.w, height: 14.h),
                  Gap(8.h),
                  SkeletonBox(width: double.infinity, height: 12.h),
                  Gap(6.h),
                  SkeletonBox(width: 180.w, height: 12.h),
                  Gap(8.h),
                  SkeletonBox(width: 100.w, height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
