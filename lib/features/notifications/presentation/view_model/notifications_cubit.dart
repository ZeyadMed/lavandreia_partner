import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/notifications/data/models/partner_notification.dart';
import 'package:lavanderia_partner/features/notifications/data/notifications_data_source.dart';

/// إشعارات المغسلة، الصفحة الجاية بتتجاب لوحدها لما اليوزر يوصل لآخر اللستة
///
/// القراءة والحذف بيتعملوا في اللستة على طول قبل ما الريكوست يرجع،
/// ولو فشل بنرجّع اللستة زي ما كانت وبنرجّع الـ [Failure] للشاشة تعرضه
class NotificationsCubit extends GenericPaginationCubit<PartnerNotification> {
  final NotificationsDataSource _dataSource;

  NotificationsCubit(this._dataSource);

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) =>
      _dataSource.getNotifications(page: page);

  bool get hasUnread => state.items.any((item) => !item.isRead);

  Future<Failure?> markAsRead(PartnerNotification notification) async {
    if (notification.isRead) return null;
    return _optimistic([
      for (final item in state.items)
        item.id == notification.id ? item.copyWith(isRead: true) : item,
    ], () => _dataSource.markAsRead(notification.id));
  }

  Future<Failure?> markAllAsRead() => _optimistic([
    for (final item in state.items) item.copyWith(isRead: true),
  ], _dataSource.markAllAsRead);

  Future<Failure?> delete(PartnerNotification notification) => _optimistic(
    state.items.where((item) => item.id != notification.id).toList(),
    () => _dataSource.deleteNotification(notification.id),
  );

  Future<Failure?> deleteAll() => _optimistic(
    [],
    _dataSource.deleteAll,
    // مفيش حاجة تانية نجيبها بعد ما اتمسح كله
    hasReachedMax: true,
  );

  Future<Failure?> _optimistic(
    List<PartnerNotification> items,
    Future<Either<Failure, void>> Function() request, {
    bool? hasReachedMax,
  }) async {
    final previous = state;
    emit(
      state.copyWith(
        status: Status.success,
        items: items,
        hasReachedMax: hasReachedMax,
      ),
    );

    final result = await request();
    return result.fold((failure) {
      if (!isClosed) emit(previous);
      return failure;
    }, (_) => null);
  }
}
