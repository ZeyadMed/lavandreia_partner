import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';

/// ريكوستات خدمات المغسلة: الخدمات وأصنافها وحفظ الأسعار
class LaundryServicesDataSource {
  final GenericDataSource _genericDataSource;

  LaundryServicesDataSource(this._genericDataSource);

  /// الريسبونس: { "data": [{ "id", "name", "icon", "items" }] }
  /// الـ items اللي جوه بنتجاهلها، الأصناف بتيجي من [getServiceItems]
  Future<Either<Failure, List<ServiceCategory>>> getServices() {
    return _genericDataSource.fetchData<ServiceCategory>(
      endpoint: Endpoints.laundryServices,
      fromJson: ServiceCategory.fromJson,
    );
  }

  /// الريسبونس: { "data": [{ "id", "name" }] }
  Future<Either<Failure, List<ServiceItem>>> getServiceItems(int serviceId) {
    return _genericDataSource.fetchData<ServiceItem>(
      endpoint: Endpoints.serviceItems(serviceId),
      fromJson: ServiceItem.fromJson,
    );
  }

  /// أصناف المغسلة بأسعارها، لستة واحدة فيها أصناف كل الخدمات
  /// الريسبونس: { "data": [{ "id", "serviceItemId", "serviceItemName", "serviceId", "serviceName", "price", ... }] }
  Future<Either<Failure, List<MyServiceItem>>> getMyServices() {
    return _genericDataSource.fetchData<MyServiceItem>(
      endpoint: Endpoints.myServices,
      fromJson: MyServiceItem.fromJson,
    );
  }

  /// بيبعت أسعار الأصناف كلها في ريكوست واحد
  /// الشكل: { "items": [{ "serviceItemId", "price" }] }
  Future<Either<Failure, void>> addMyServices(List<ServiceItemPrice> prices) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.myServices,
      data: {'items': prices.map((price) => price.toJson()).toList()},
    );
  }

  /// تعديل أسعار أصناف موجودة، نفس شكل الإضافة بس PUT
  Future<Either<Failure, void>> updateMyServices(
    List<ServiceItemPrice> prices,
  ) {
    return _genericDataSource.updateData<Null>(
      endpoint: Endpoints.myServices,
      data: {'items': prices.map((price) => price.toJson()).toList()},
    );
  }

  /// حذف أصناف من المغسلة، الشكل: { "serviceItemIds": [1, 2] }
  Future<Either<Failure, void>> deleteMyServices(List<int> serviceItemIds) {
    return _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.myServices,
      data: {'serviceItemIds': serviceItemIds},
    );
  }
}
