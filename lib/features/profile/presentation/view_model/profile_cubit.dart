import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';
import 'package:lavanderia_partner/features/profile/data/profile_data_source.dart';

/// بيانات المغسلة، الداتا بتبقى في state.data وبتتجاب بـ fetchDataMap
class ProfileCubit extends BaseCubit<PartnerProfile> {
  ProfileCubit(ProfileDataSource dataSource)
    : super(
        fetchFunction: () async => throw UnimplementedError(),
        fetchFunctionMap: dataSource.getProfile,
      );
}
