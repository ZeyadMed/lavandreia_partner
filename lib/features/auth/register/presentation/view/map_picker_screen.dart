import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/helpers/location_service.dart';
import 'package:lavanderia_partner/core/helpers/place_search_service.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/custom_button.dart';

/// اللي بيترجع لشاشة الموقع بعد ما اليوزر يأكد الدبوس
class PickedLocation {
  final double latitude;
  final double longitude;

  /// العنوان النصي، ممكن يبقى فاضي لو الـ reverse geocoding فشل
  final String address;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

/// شاشة اختيار الموقع على الخريطة
/// اليوزر يقدر يدور باسم المنطقة، أو يحرك الخريطة، أو يجيب موقعه الحالي
/// والدبوس ثابت في النص والخريطة هي اللي بتتحرك تحته
class MapPickerScreen extends StatefulWidget {
  /// الموقع اللي اليوزر اختاره قبل كده، عشان يفتح عليه بدل الافتراضي
  final double? initialLatitude;
  final double? initialLongitude;

  /// كود دولة المغسلة عشان البحث يتحصر فيها
  final String? countryCode;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.countryCode,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  /// طرابلس، نقطة البداية لو مفيش موقع محفوظ
  static const LatLng _fallbackCenter = LatLng(32.8872, 13.1913);

  final MapController _mapController = MapController();
  final PlaceSearchService _searchService = PlaceSearchService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  /// إحداثيات الدبوس الحالية، بتتحدث مع كل حركة للخريطة
  late LatLng _pinPosition;

  /// العنوان النصي للدبوس، بيتجاب بعد ما الحركة تقف
  String _address = '';
  bool _isResolvingAddress = false;

  List<PlaceResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLocating = false;

  /// بيمنع إن كل حرف في البحث يبعت request
  Timer? _searchDebounce;

  /// بيستنى شوية بعد ما الخريطة تقف قبل ما يجيب العنوان
  Timer? _addressDebounce;

  /// بيتحط قبل ما إحنا نحرك الخريطة بنفسنا، عشان _onMapEvent
  /// يفرق بين حركة اليوزر والحركة اللي إحنا عاملينها ومعانا عنوانها
  bool _isProgrammaticMove = false;

  @override
  void initState() {
    super.initState();
    _pinPosition = LatLng(
      widget.initialLatitude ?? _fallbackCenter.latitude,
      widget.initialLongitude ?? _fallbackCenter.longitude,
    );
    // لو فاتح على موقع محفوظ نجيب عنوانه على طول
    if (widget.initialLatitude != null) _resolveAddress();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _addressDebounce?.cancel();
    _searchController.dispose();
    _searchService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// بيتنادى مع كل حركة للخريطة
  /// بيحدث الدبوس على طول بس بيأجل جلب العنوان لحد ما الحركة تهدى
  void _onMapEvent(MapEvent event) {
    final center = event.camera.center;
    if (center == _pinPosition) return;

    // الحركة اللي إحنا عاملينها بنفسنا (بحث أو موقعي الحالي) عندها العنوان
    // بالفعل، فبنتجاهلها هنا عشان مانعملش reverse زيادة ونمسح عنوان صح
    if (_isProgrammaticMove) {
      _isProgrammaticMove = false;
      setState(() {
        _pinPosition = center;
        // أي بحث عنوان قديم بقى ملغي، فاللودر لازم يقف
        _isResolvingAddress = false;
      });
      return;
    }

    setState(() {
      _pinPosition = center;
      _address = '';
    });

    _addressDebounce?.cancel();
    _addressDebounce = Timer(
      const Duration(milliseconds: 700),
      _resolveAddress,
    );
  }

  Future<void> _resolveAddress() async {
    if (!mounted) return;
    setState(() => _isResolvingAddress = true);

    // بنمسك النقطة اللي بندور على عنوانها عشان لو اليوزر حرك تاني
    // مانحطش عنوان قديم على مكان جديد
    final target = _pinPosition;
    final result = await _searchService.reverse(
      target.latitude,
      target.longitude,
    );

    if (!mounted) return;

    // اليوزر حرك الخريطة تاني وإحنا بندور، النتيجة دي بقت قديمة
    // بنسيب اللودر شغال لأن فيه نداء تاني جاي للنقطة الجديدة
    if (target != _pinPosition) return;

    setState(() {
      _address = result ?? '';
      _isResolvingAddress = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    final results = await _searchService.search(
      query,
      countryCode: widget.countryCode,
    );

    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  /// بينقل الخريطة على النتيجة اللي اليوزر ضغط عليها
  void _selectResult(PlaceResult result) {
    FocusScope.of(context).unfocus();
    final target = LatLng(result.latitude, result.longitude);

    _isProgrammaticMove = true;
    _mapController.move(target, 16);
    _addressDebounce?.cancel();

    setState(() {
      _pinPosition = target;
      // عندنا العنوان من نتيجة البحث فمش محتاجين reverse تاني
      _address = result.displayName;
      _searchResults = [];
      _searchController.clear();
    });
  }

  /// بيجيب موقع اليوزر الحالي وينقل الخريطة عليه
  Future<void> _goToCurrentLocation() async {
    setState(() => _isLocating = true);
    final result = await _locationService.getCurrentAddress();
    if (!mounted) return;

    setState(() => _isLocating = false);

    if (!result.isSuccess || result.latitude == null) {
      _showMessage(
        result.needsSettings ? 'location_permission_denied' : 'location_failed',
      );
      return;
    }

    final target = LatLng(result.latitude!, result.longitude!);
    _isProgrammaticMove = true;
    _mapController.move(target, 16);
    _addressDebounce?.cancel();

    setState(() {
      _pinPosition = target;
      _address = result.address;
    });
  }

  void _showMessage(String messageKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Label(text: messageKey.tr(), style: TextStyles.whiteBold14),
        backgroundColor: AppColors.redColor,
      ),
    );
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedLocation(
        latitude: _pinPosition.latitude,
        longitude: _pinPosition.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Stack(
        children: [
          _buildMap(),
          _buildCenterPin(),
          _buildSearchBar(),
          _buildMyLocationButton(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pinPosition,
        initialZoom: widget.initialLatitude != null ? 16 : 12,
        minZoom: 3,
        maxZoom: 18,
        onMapEvent: _onMapEvent,
        interactionOptions: const InteractionOptions(
          // بنقفل الدوران عشان الدبوس الثابت مايبقاش مربك
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.lavanderia.partner',
          maxZoom: 19,
        ),
      ],
    );
  }

  /// الدبوس ثابت في نص الشاشة، الخريطة هي اللي بتتحرك تحته
  /// مرفوع شوية لفوق عشان سنّه يقع على النقطة بالظبط
  Widget _buildCenterPin() {
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 36.h),
          child: Icon(
            Icons.location_on,
            size: 46.sp,
            color: AppColors.redColor2,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8.h,
      left: 12.w,
      right: 12.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              Gap(8.w),
              Expanded(child: _buildSearchField()),
            ],
          ),
          if (_searchResults.isNotEmpty) ...[
            Gap(8.h),
            _buildResultsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: TextStyles.darkRegular14,
        decoration: InputDecoration(
          hintText: 'search_area_hint'.tr(),
          hintStyle: TextStyles.greyColor2Regular14,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.greyColor3,
            size: 20.sp,
          ),
          suffixIcon: _isSearching
              ? Padding(
                  padding: EdgeInsets.all(12.w),
                  child: SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, size: 18.sp),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchResults = []);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Container(
      constraints: BoxConstraints(maxHeight: 260.h),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.place_outlined,
              color: AppColors.primaryColor,
              size: 20.sp,
            ),
            title: Label(
              text: result.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.darkRegular14,
            ),
            onTap: () => _selectResult(result),
          );
        },
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      // فوق الشيت السفلي
      bottom: 210.h,
      right: 16.w,
      child: _CircleIconButton(
        icon: Icons.my_location,
        isLoading: _isLocating,
        onTap: _isLocating ? null : _goToCurrentLocation,
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 0),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LocalizedLabel(
                text: 'selected_location',
                style: TextStyles.blackBold16,
              ),
              Gap(8.h),
              _buildAddressPreview(),
              Gap(6.h),
              Label(
                // الإحداثيات بتتعرض دايماً عشان اليوزر يتأكد إن فيه نقطة متحددة
                text:
                    '${_pinPosition.latitude.toStringAsFixed(6)}, '
                    '${_pinPosition.longitude.toStringAsFixed(6)}',
                style: TextStyles.darkRegular12.copyWith(
                  color: AppColors.greyColor3,
                ),
              ),
              Gap(14.h),
              CustomButton(
                onPressed: _confirm,
                title: 'confirm_location'.tr(),
              ),
              Gap(12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPreview() {
    if (_isResolvingAddress) {
      return Row(
        children: [
          SizedBox(
            width: 14.w,
            height: 14.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          Gap(8.w),
          LocalizedLabel(
            text: 'loading_address',
            style: TextStyles.darkRegular14.copyWith(
              color: AppColors.greyColor3,
            ),
          ),
        ],
      );
    }

    return Label(
      text: _address.isEmpty ? 'move_map_to_pick'.tr() : _address,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyles.darkRegular14,
    );
  }
}

/// زرار دائري أبيض بظل، بيستخدم للرجوع ولموقعي الحالي
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(12.w),
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: AppColors.primaryColor, size: 20.sp),
      ),
    );
  }
}
