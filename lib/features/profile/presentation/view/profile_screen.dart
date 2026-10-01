import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/realtime/realtime_service.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/auth/login/data/login_data_source.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_profile.dart';
import 'package:lavanderia_partner/features/profile/data/models/partner_profile.dart';
import 'package:lavanderia_partner/features/profile/data/profile_data_source.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/edit_laundry_screen.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/legal_page_screen.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/reviews_screen.dart';
import 'package:lavanderia_partner/features/notifications/presentation/view/notifications_screen.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/support_screen.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/working_hours_screen.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/logout_dialog.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/profile_header.dart';
import 'package:lavanderia_partner/features/profile/presentation/view/widgets/profile_widgets.dart';
import 'package:lavanderia_partner/features/profile/presentation/view_model/profile_cubit.dart';
import 'package:lavanderia_partner/features/wallet/presentation/view/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// بيانات المغسلة من GET api/laundry/profile
  final ProfileCubit _profileCubit = ProfileCubit(getIt<ProfileDataSource>())
    ..fetchDataMap();

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  /// بيفتح صفحة التعديل ببيانات السيرفر، ولو اليوزر حفظ بنجيب البروفايل تاني
  /// تعديل الموقع جوه الصفحة دي مش صفحة منفصلة
  Future<void> _openEdit(PartnerProfile profile) async {
    final updated = await Navigator.of(context).push<LaundryProfile>(
      MaterialPageRoute(
        builder: (_) =>
            EditLaundryScreen(profile: LaundryProfile.fromPartner(profile)),
      ),
    );
    if (updated == null || !mounted) return;

    context.showSuccessMessage('profile_updated'.tr());
    _profileCubit.fetchDataMap();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout() async {
    final confirmed = await showLogoutDialog(context);
    if (confirmed != true || !mounted) return;

    // الريكوست بيمسح التوكنز بنفسه حتى لو فشل، فبنكمل للوجين في الحالتين
    context.showLoadingDialog(message: 'logging_out');
    await RealtimeService.disconnect();
    await getIt<LoginDataSource>().logout();
    if (!mounted) return;
    Navigator.of(context).pop();

    // go بدل push عشان اليوزر مايقدرش يرجع للتطبيق بزرار الرجوع
    context.go(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      body: BlocBuilder<ProfileCubit, BaseState<PartnerProfile>>(
        bloc: _profileCubit,
        // بنحتفظ بالبيانات القديمة وهي بتتحدث عشان الصفحة مارجعش فاضية
        buildWhen: (previous, current) => current.data != null,
        builder: (context, state) {
          final profile = state.data;
          return Column(
            children: [
              ProfileHeader(profile: profile),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryColor,
                  onRefresh: _profileCubit.fetchDataMap,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(profile),
                        Gap(16.h),
                        _buildMenuCard(profile),
                        Gap(16.h),
                        _LogoutButton(onTap: _logout),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// كارت بيانات التواصل والعنوان، وبيعرض — لحد ما البيانات توصل
  Widget _buildInfoCard(PartnerProfile? profile) {
    return ProfileCard(
      children: [
        ProfileInfoRow(
          icon: Icons.phone_outlined,
          labelKey: 'phone_number',
          value: profile?.phoneNumber ?? '',
          isLtr: true,
        ),
        ProfileInfoRow(
          icon: Icons.person_outline,
          labelKey: 'owner_phone',
          value: profile?.ownerPhoneNumber ?? '',
          isLtr: true,
        ),
        ProfileInfoRow(
          icon: Icons.location_city_outlined,
          labelKey: 'city',
          value: profile?.cityName ?? '',
        ),
        ProfileInfoRow(
          icon: Icons.location_on_outlined,
          labelKey: 'address',
          value: profile?.address ?? '',
          showDivider: false,
        ),
      ],
    );
  }

  /// ليستة الإعدادات
  Widget _buildMenuCard(PartnerProfile? profile) {
    return ProfileCard(
      children: [
        ProfileMenuTile(
          icon: Icons.edit_outlined,
          labelKey: 'edit_laundry_info',
          // التعديل بيستنى البيانات توصل الأول
          onTap: () {
            if (profile != null) _openEdit(profile);
          },
        ),
        ProfileMenuTile(
          icon: Icons.account_balance_wallet_outlined,
          labelKey: 'my_wallet',
          onTap: () => _open(const WalletScreen()),
        ),
        ProfileMenuTile(
          icon: Icons.notifications_none_rounded,
          labelKey: 'notifications',
          onTap: () => _open(const NotificationsScreen()),
        ),
        ProfileMenuTile(
          icon: Icons.access_time,
          labelKey: 'working_hours',
          onTap: () => _open(const WorkingHoursScreen()),
        ),
        ProfileMenuTile(
          icon: Icons.star_outline_rounded,
          labelKey: 'my_reviews',
          onTap: () => _open(const ReviewsScreen()),
        ),
        ProfileMenuTile(
          icon: Icons.headset_mic_outlined,
          labelKey: 'support_and_help',
          onTap: () => _open(const SupportScreen()),
        ),
        ProfileMenuTile(
          icon: Icons.description_outlined,
          labelKey: 'terms_and_conditions',
          onTap: () => _open(const LegalPageScreen.terms()),
        ),
        ProfileMenuTile(
          icon: Icons.privacy_tip_outlined,
          labelKey: 'privacy_policy',
          onTap: () => _open(const LegalPageScreen.privacy()),
          showDivider: false,
        ),
      ],
    );
  }
}

/// زرار تسجيل الخروج الأحمر تحت الليستة
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.redColor2.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.redColor2.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalizedLabel(
              text: 'logout',
              style: TextStyles.boldStyle(
                15,
                color: AppColors.redColor2,
                weight: FontWeight.w700,
              ),
            ),
            Gap(10.w),
            Icon(Icons.logout_rounded, size: 19.sp, color: AppColors.redColor2),
          ],
        ),
      ),
    );
  }
}
