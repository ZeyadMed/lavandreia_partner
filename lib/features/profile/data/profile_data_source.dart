import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_profile.dart';
import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';

/// ريكوستات بيانات المغسلة
class ProfileDataSource {
  final GenericDataSource _genericDataSource;

  ProfileDataSource(this._genericDataSource);

  /// الريسبونس: { "data": { "id", "name", "address", "imageUrl", ... } }
  Future<Either<Failure, PartnerProfile>> getProfile() {
    return _genericDataSource.fetchResult<PartnerProfile>(
      endpoint: Endpoints.laundryProfile,
      fromJson: PartnerProfile.fromJson,
    );
  }

  /// بيبعت البيانات كـ multipart عشان الصورة بتتبعت كملف
  Future<Either<Failure, void>> updateProfile(LaundryProfile profile) {
    return _genericDataSource.updateFormData(
      endpoint: Endpoints.laundryProfile,
      data: profile.toFormData(),
    );
  }

  /// بيحذف الحساب نهائياً، ولو نجح بيمسح التوكنز عشان الجلسة تخلص معاه
  Future<Either<Failure, void>> deleteAccount() async {
    final result = await _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.deleteAccount,
    );
    if (result.isSuccess) await CacheManager.clearTokens();
    return result;
  }
}
