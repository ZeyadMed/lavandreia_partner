import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/services/data/laundry_services_data_source.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';

/// لستة الخدمات، الداتا بتبقى في state.items
class ServicesCubit extends BaseCubit<ServiceCategory> {
  ServicesCubit(LaundryServicesDataSource dataSource)
    : super(fetchFunction: dataSource.getServices);
}

/// أصناف خدمة واحدة، بيتعمل لكل خدمة لما اليوزر يفتحها
class ServiceItemsCubit extends BaseCubit<ServiceItem> {
  ServiceItemsCubit({
    required LaundryServicesDataSource dataSource,
    required int serviceId,
  }) : super(fetchFunction: () => dataSource.getServiceItems(serviceId));
}

/// حفظ الأسعار، الـ status بس هو اللي بيفرق (loading / success / failure)
class SaveMyServicesCubit extends Cubit<BaseState<void>> {
  final LaundryServicesDataSource _dataSource;

  SaveMyServicesCubit(this._dataSource) : super(const BaseState<void>());

  Future<void> save(List<ServiceItemPrice> prices) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.addMyServices(prices);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (_) => emit(state.copyWith(status: Status.success)),
    );
  }
}

/// أصناف المغسلة في صفحة الخدمات
/// بعد التعديل أو الحذف بنحدّث اللستة محلياً بدل ما نجيبها تاني
class MyServicesCubit extends BaseCubit<MyServiceItem> {
  MyServicesCubit(LaundryServicesDataSource dataSource)
    : super(fetchFunction: dataSource.getMyServices);

  void applyPrices(List<ServiceItemPrice> prices) {
    final newPrices = {
      for (final price in prices) price.serviceItemId: price.price,
    };
    emit(
      state.copyWith(
        items: [
          for (final item in state.items)
            newPrices.containsKey(item.serviceItemId)
                ? item.copyWith(price: newPrices[item.serviceItemId])
                : item,
        ],
      ),
    );
  }

  void removeItems(List<int> serviceItemIds) {
    final ids = serviceItemIds.toSet();
    emit(
      state.copyWith(
        items: state.items
            .where((item) => !ids.contains(item.serviceItemId))
            .toList(),
      ),
    );
  }
}

/// ريكوست تعديل أو حذف على أصناف المغسلة
/// الـ data بتفضل شايلة اللي اتبعت عشان الشاشة تطبقه على اللستة بعد النجاح
class MyServicesRequestCubit<T> extends Cubit<BaseState<T>> {
  final Future<Either<Failure, void>> Function(T payload) _request;

  MyServicesRequestCubit(this._request) : super(BaseState<T>());

  Future<void> submit(T payload) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: Status.loading, data: payload));

    final result = await _request(payload);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (_) => emit(state.copyWith(status: Status.success)),
    );
  }
}

/// PUT بالأسعار الجديدة
class UpdateMyServicesCubit
    extends MyServicesRequestCubit<List<ServiceItemPrice>> {
  UpdateMyServicesCubit(LaundryServicesDataSource dataSource)
    : super(dataSource.updateMyServices);
}

/// DELETE بالـ serviceItemIds اللي اتحددت
class DeleteMyServicesCubit extends MyServicesRequestCubit<List<int>> {
  DeleteMyServicesCubit(LaundryServicesDataSource dataSource)
    : super(dataSource.deleteMyServices);
}
