import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/wallet/data/models/wallet_transaction.dart';
import 'package:lavanderia_partner/features/wallet/data/wallet_data_source.dart';

/// رصيد المحفظة، الداتا بتبقى في state.data وبتتجاب بـ fetchDataMap
class WalletBalanceCubit extends BaseCubit<double> {
  WalletBalanceCubit(WalletDataSource dataSource)
    : super(
        fetchFunction: () async => throw UnimplementedError(),
        fetchFunctionMap: dataSource.getBalance,
      );
}

/// حركات المحفظة، الصفحة الجاية بتتجاب لوحدها لما اليوزر يوصل لآخر اللستة
class WalletTransactionsCubit
    extends GenericPaginationCubit<WalletTransaction> {
  final WalletDataSource _dataSource;

  WalletTransactionsCubit(this._dataSource);

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) =>
      _dataSource.getTransactions(page: page);
}
