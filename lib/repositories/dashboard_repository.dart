import '../models/stock_model.dart';
import '../models/user_model.dart';
import 'stock_repository.dart';
import 'staff_repository.dart';
import 'stream_combine.dart';

class DashboardInput {
  final List<StockModel> products;
  final int? sales, staffCount;
  final double? income;
  const DashboardInput(this.products, this.sales, this.income, this.staffCount);
}

class DashboardRepository {
  final StockRepository stock;
  final StaffRepository staff;
  DashboardRepository(this.stock, this.staff);
  Stream<DashboardInput> watch(UserModel user) {
    if (!user.isAdmin) {
      return stock.products().map((p) => DashboardInput(p, null, null, null));
    }
    return combineStreams([
      stock.products(),
      stock.report(),
      staff.watch(),
    ]).map((data) {
      final report = data[1] as Map<String, dynamic>;
      return DashboardInput(
        data[0] as List<StockModel>,
        (report['totalSales'] as num? ?? 0).toInt(),
        (report['totalIncome'] as num? ?? 0).toDouble(),
        (data[2] as List<UserModel>).where((u) => u.role == 'staff').length,
      );
    });
  }
}
