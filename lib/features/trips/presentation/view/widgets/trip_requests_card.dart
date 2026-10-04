import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/order_details_widgets.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_partner/features/trips/presentation/view/widgets/driver_offer_tile.dart';
import 'package:lavanderia_partner/features/trips/presentation/view_model/trips_cubits.dart';

/// كارت الدليفرية اللي طلبوا الرحلة، المغسلة بتوافق على واحد منهم
/// الدليفري بيتعيّن على الرحلة بس بعد الموافقة، وباقي الطلبات بتترفض لوحدها
class TripRequestsCard extends StatefulWidget {
  final DeliveryTrip trip;

  /// بتتنادى بعد الموافقة عشان صفحة الطلب تجيب حالته الجديدة
  final VoidCallback onApproved;

  const TripRequestsCard({
    super.key,
    required this.trip,
    required this.onApproved,
  });

  @override
  State<TripRequestsCard> createState() => _TripRequestsCardState();
}

class _TripRequestsCardState extends State<TripRequestsCard> {
  late final TripRequestsCubit _requestsCubit = TripRequestsCubit(
    getIt<TripsDataSource>(),
    widget.trip.id,
  )..fetchData();

  late final TripRequestActionCubit _actionCubit = TripRequestActionCubit(
    getIt<TripsDataSource>(),
    widget.trip.id,
  );

  @override
  void dispose() {
    _requestsCubit.close();
    _actionCubit.close();
    super.dispose();
  }

  void _onActionStateChanged(
    BuildContext context,
    BaseState<TripRequest> state,
  ) {
    if (state.isSuccess && state.data != null) {
      _requestsCubit.replace(state.data!);
      if (state.data!.isApproved) {
        context.showSuccessMessage('driver_approved'.tr());
        widget.onApproved();
      }
      return;
    }
    // أخطاء الاتصال والـ validation الـ ApiConsumer بيعرضها بنفسه
    final failure = state.failure;
    if (state.isFailure &&
        (failure is ServerFailure || failure is UnknownFailure)) {
      context.showErrorMessage(failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleKey = widget.trip.type == DeliveryTripType.pickup
        ? 'pickup_driver_requests'
        : 'dropoff_driver_requests';

    return BlocListener<TripRequestActionCubit, BaseState<TripRequest>>(
      bloc: _actionCubit,
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onActionStateChanged,
      child: DetailsCard(
        titleKey: titleKey,
        child: BlocBuilder<TripRequestsCubit, BaseState<TripRequest>>(
          bloc: _requestsCubit,
          builder: (context, state) {
            if (state.isLoading || state.isInitial) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                ),
              );
            }

            // الأقرب الأول، والمرفوض والملغي مش بيظهروا
            final requests =
                state.items
                    .where((r) => !r.isRejected && !r.isCancelled)
                    .toList()
                  ..sort(TripRequest.compareByArrival);
            // لو فيه طلب اتوافق عليه بنعرضه هو بس من غير زراير
            final approved = requests.where((r) => r.isApproved).firstOrNull;

            if (approved != null) {
              return DriverOfferTile(
                request: approved,
                trailing: const _ApprovedChip(),
              );
            }

            if (requests.isEmpty) {
              return _NoRequests(
                text: state.isFailure
                    ? 'driver_requests_load_failed'
                    : 'no_driver_requests_yet',
                onRefresh: _requestsCubit.fetchData,
              );
            }

            return BlocBuilder<TripRequestActionCubit, BaseState<TripRequest>>(
              bloc: _actionCubit,
              builder: (context, actionState) => Column(
                children: [
                  for (final (index, request) in requests.indexed)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: DriverOfferTile(
                        request: request,
                        isClosest: index == 0 && requests.length > 1,
                        loadingAction:
                            actionState.isLoading &&
                                _actionCubit.pendingRequestId == request.id
                            ? _actionCubit.pendingAction
                            : null,
                        isBusy: actionState.isLoading,
                        onApprove: () => _actionCubit.approve(request),
                        onReject: () => _actionCubit.reject(request),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ApprovedChip extends StatelessWidget {
  const _ApprovedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: const Color(0xffE3F5EA),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: LocalizedLabel(
        text: 'driver_assigned',
        style: TextStyles.boldStyle(
          12,
          color: const Color(0xff0E8C4F),
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// لسه محدش طلب الرحلة، أو الليستة فشلت
class _NoRequests extends StatelessWidget {
  final String text;
  final VoidCallback onRefresh;

  const _NoRequests({required this.text, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.hourglass_empty_rounded,
          size: 20.sp,
          color: AppColors.greyColor5,
        ),
        Gap(8.w),
        Expanded(
          child: LocalizedLabel(
            text: text,
            style: TextStyles.darkRegular12.copyWith(
              color: AppColors.greyColor3,
            ),
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: Icon(
            Icons.refresh_rounded,
            size: 20.sp,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}
