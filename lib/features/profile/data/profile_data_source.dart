import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
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
}
