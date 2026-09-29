import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';
import 'package:lavanderia_partner/core/widget/skeleton.dart';
import 'package:lavanderia_partner/features/wallet/data/models/wallet_transaction.dart';
import 'package:lavanderia_partner/features/wallet/data/wallet_data_source.dart';
import 'package:lavanderia_partner/features/wallet/presentation/view_model/wallet_cubits.dart';

/// صفحة المحفظة: الرصيد فوق وتحته حركات المحفظة صفحة ورا صفحة مع السكرول
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final WalletBalanceCubit _balanceCubit = WalletBalanceCubit(
    getIt<WalletDataSource>(),
  )..fetchDataMap();

  late final WalletTransactionsCubit _transactionsCubit =
      WalletTransactionsCubit(getIt<WalletDataSource>())
        ..initPagination()
        ..fetch(page: 1);

  @override
  void dispose() {
    _balanceCubit.close();
    _transactionsCubit.close();
    super.dispose();
  }

  Future<void> _refresh() =>
      Future.wait([_balanceCubit.fetchDataMap(), _transactionsCubit.refresh()]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semiWhiteColor3,
      appBar: const CustomAppBar(title: 'my_wallet'),
      body: BlocBuilder<WalletTransactionsCubit, BaseState<WalletTransaction>>(
        bloc: _transactionsCubit,
        builder: (context, state) => RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: _refresh,
          child: ListView(
            controller: _transactionsCubit.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              BlocBuilder<WalletBalanceCubit, BaseState<double>>(
                bloc: _balanceCubit,
                builder: (context, balanceState) => _BalanceCard(
                  state: balanceState,
                  onRetry: _balanceCubit.fetchDataMap,
                ),
              ),
              Gap(20.h),
              LocalizedLabel(
                text: 'wallet_transactions',
                style: TextStyles.darkBold16,
              ),
              Gap(12.h),
              ..._buildTransactions(state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactions(BaseState<WalletTransaction> state) {
    // السحب للتحديث بيرجع لـ loading، فبنسيب اللستة القديمة ظاهرة لحد ما الجديدة توصل
    if (state.items.isEmpty) {
      if (state.isFailure) {
        return [
          _CenteredMessage(
            text: 'wallet_transactions_load_failed',
            color: AppColors.redColor,
            onRetry: _transactionsCubit.refresh,
          ),
        ];
      }
      if (state.isSuccess) {
        return const [
          _CenteredMessage(
            text: 'no_wallet_transactions',
            color: AppColors.greyColor3,
            icon: Icons.receipt_long_outlined,
          ),
        ];
      }
      return List.generate(
        5,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: const _TransactionCardSkeleton(),
        ),
      );
    }

    return [
      for (final transaction in state.items)
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: _TransactionCard(transaction: transaction),
        ),
      _ListFooter(
        state: state,
        onRetry: () => _transactionsCubit.fetch(page: state.page),
      ),
    ];
  }
}

/// الكارت الأزرق اللي فيه الرصيد الحالي
class _BalanceCard extends StatelessWidget {
  final BaseState<double> state;
  final VoidCallback onRetry;

  const _BalanceCard({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final balance = state.data;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff4A7FE8), AppColors.primaryColor],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedLabel(
                  text: 'wallet_balance',
                  style: TextStyles.whiteText(
                    14,
                    weight: FontWeight.w400,
                  ).copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                Gap(8.h),
                _buildBalance(balance),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 28.sp,
              color: AppColors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalance(double? balance) {
    // بنعرض الرصيد القديم وهو بيتحدث عشان الكارت مايرجعش فاضي
    if (balance != null) {
      return Text(
        formatWalletAmount(balance),
        style: TextStyles.whiteText(28, weight: FontWeight.w800),
      );
    }
    if (state.isFailure) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRetry,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, color: AppColors.whiteColor),
            Gap(6.w),
            LocalizedLabel(
              text: 'try_again',
              style: TextStyles.whiteText(15, weight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 34.h,
      child: const Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            color: AppColors.whiteColor,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}

/// كارت حركة واحدة: الوصف والنوع والتاريخ والمبلغ
class _TransactionCard extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final createdAt = transaction.createdAt;
    final amountColor = transaction.isCredit
        ? AppColors.greenColor
        : AppColors.redColor2;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.25),
          width: 0.9,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              size: 20.sp,
              color: amountColor,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transaction.description.isNotEmpty) ...[
                  Text(transaction.description, style: TextStyles.darkBold14),
                  Gap(6.h),
                ],
                // النوع بيتعرض زي ما هو من السيرفر من غير ترجمة
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    transaction.type,
                    textDirection: TextDirection.ltr,
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                if (createdAt != null) ...[
                  Gap(6.h),
                  Text(
                    DateFormat(
                      'd MMM yyyy - h:mm a',
                      context.locale.toString(),
                    ).format(createdAt),
                    style: TextStyles.darkRegular12.copyWith(
                      color: AppColors.greyColor3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Gap(8.w),
          Text(
            transaction.displayAmount,
            textDirection: TextDirection.ltr,
            style: TextStyles.boldStyle(
              15,
              color: amountColor,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// آخر اللستة: لودينج الصفحة الجاية أو زرار إعادة المحاولة لو فشلت
class _ListFooter extends StatelessWidget {
  final BaseState<WalletTransaction> state;
  final VoidCallback onRetry;

  const _ListFooter({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }
    if (state.isLoadingMoreFauilare) {
      return Center(child: _RetryButton(onRetry: onRetry));
    }
    return const SizedBox.shrink();
  }
}

/// رسالة تحت الرصيد للفشل أو اللستة الفاضية
class _CenteredMessage extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback? onRetry;

  const _CenteredMessage({
    required this.text,
    required this.color,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 56.sp, color: AppColors.greyColor5),
            Gap(8.h),
          ],
          LocalizedLabel(
            text: text,
            textAlign: TextAlign.center,
            style: TextStyles.darkRegular14.copyWith(color: color),
          ),
          if (onRetry != null) _RetryButton(onRetry: onRetry!),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, color: AppColors.primaryColor),
      label: LocalizedLabel(
        text: 'try_again',
        style: TextStyles.darkBold14.copyWith(color: AppColors.primaryColor),
      ),
    );
  }
}

/// لودينج أول صفحة بنفس شكل [_TransactionCard]
class _TransactionCardSkeleton extends StatelessWidget {
  const _TransactionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.25),
          width: 0.9,
        ),
      ),
      child: SkeletonShimmer(
        child: Row(
          children: [
            SkeletonBox(width: 40.r, height: 40.r, radius: 20.r),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160.w, height: 14.h),
                  Gap(6.h),
                  SkeletonBox(width: 80.w, height: 16.h),
                  Gap(6.h),
                  SkeletonBox(width: 110.w, height: 12.h),
                ],
              ),
            ),
            SkeletonBox(width: 60.w, height: 16.h),
          ],
        ),
      ),
    );
  }
}
