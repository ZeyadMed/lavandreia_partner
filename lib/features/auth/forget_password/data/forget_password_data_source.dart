import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';

/// ريكوستات نسيت كلمة المرور: طلب الكود وبعدين تعيين كلمة المرور الجديدة
/// مفيش خطوة verify otp في النص، الكود بيتبعت مع كلمة المرور الجديدة
class ForgetPasswordDataSource {
  final GenericDataSource _genericDataSource;

  ForgetPasswordDataSource(this._genericDataSource);

  /// نوع الحساب ثابت في الريكوستين
  static const String _accountType = 'Laundry';

  /// بيبعت { phoneNumber, accountType } والسيرفر بيبعت كود للرقم
  Future<Either<Failure, void>> forgotPassword({required String phoneNumber}) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.forgetPassword,
      data: {'phoneNumber': phoneNumber, 'accountType': _accountType},
    );
  }

  /// بيبعت { phoneNumber, accountType, code, newPassword }
  Future<Either<Failure, void>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.resetPassword,
      data: {
        'phoneNumber': phoneNumber,
        'accountType': _accountType,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }
}
