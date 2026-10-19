import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/profile/data/models/privacy_policy.dart';
import 'package:lavanderia_partner/features/profile/data/models/support_contacts.dart';

/// ريكوستات بيانات التطبيق اللي بتتغير من لوحة التحكم:
/// وسائل التواصل وسياسة الخصوصية
class AppInfoDataSource {
  final GenericDataSource _genericDataSource;

  AppInfoDataSource(this._genericDataSource);

  /// الريسبونس: { "data": { "phoneNumber1", "phoneNumber2", "email" } }
  Future<Either<Failure, SupportContacts>> getContacts() {
    return _genericDataSource.fetchResult<SupportContacts>(
      endpoint: Endpoints.contacts,
      fromJson: SupportContacts.fromJson,
    );
  }

  /// الريسبونس: { "data": { "content": "<h1>..</h1>", "updatedAt" } }
  Future<Either<Failure, PrivacyPolicy>> getPrivacyPolicy() {
    return _genericDataSource.fetchResult<PrivacyPolicy>(
      endpoint: Endpoints.privacyPolicy,
      fromJson: PrivacyPolicy.fromJson,
    );
  }
}
