import 'package:simple/data/repositories/auth/auth_repository.dart';
import 'package:simple/data/repositories/auth/auth_repository_impl.dart';
import 'package:simple/data/repositories/category/category_repository.dart';
import 'package:simple/data/repositories/category/category_repository_impl.dart';
import 'package:simple/data/repositories/order/order_repository.dart';
import 'package:simple/data/repositories/order/order_repository_impl.dart';
import 'package:simple/data/repositories/product/product_repository.dart';
import 'package:simple/data/repositories/product/product_repository_impl.dart';
import 'package:simple/data/repositories/report/report_repository.dart';
import 'package:simple/data/repositories/report/report_repository_impl.dart';
import 'package:simple/data/repositories/shift_closing/shift_closing_repository.dart';
import 'package:simple/data/repositories/shift_closing/shift_closing_repository_impl.dart';
import 'package:simple/data/repositories/stock_in/stock_in_repository.dart';
import 'package:simple/data/repositories/stock_in/stock_in_repository_impl.dart';
import 'package:simple/injector/injector.dart';

class RepositoryModule {
  RepositoryModule._();

  static void init() {
    final injector = Injector.instance;
    injector
      ..registerFactory<AuthRepository>(
              () => AuthRepositoryImpl(apiClient: injector()))
      ..registerFactory<CategoryRepository>(
              () => CategoryRepositoryImpl(apiClient: injector()))
      ..registerFactory<OrderRepository>(
              () => OrderRepositoryImpl(apiClient: injector()))
      ..registerFactory<ProductRepository>(
              () => ProductRepositoryImpl(apiClient: injector()))
      ..registerFactory<ReportRepository>(
              () => ReportRepositoryImpl(apiClient: injector()))
      ..registerFactory<StockInRepository>(
              () => StockInRepositoryImpl(apiClient: injector()))
      ..registerFactory<ShiftClosingRepository>(
              () => ShiftClosingRepositoryImpl(apiClient: injector()));
    //         () => ExpenseRepositoryImpl(apiClient: injector()))
    // ..registerFactory<HomeRepository>(
    //         () => HomeRepositoryImpl(apiClient: injector()))
    // ..registerFactory<OrdersRepository>(
    //         () => OrdersRepositoryImpl(apiClient: injector()))
    // ..registerFactory<ShiftCloseRepository>(
    //         () => ShiftCloseRepositoryImpl(apiClient: injector()))
    // ..registerFactory<CommonRepository>(
    //         () => CommonRepositoryImpl(apiClient: injector()));
  }
}