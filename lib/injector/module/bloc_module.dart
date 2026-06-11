import 'package:simple/Bloc/Authentication/login_bloc.dart';
import 'package:simple/Bloc/Category/category_bloc.dart';
import 'package:simple/Bloc/Order/order_list_bloc.dart';
import 'package:simple/Bloc/Products/product_category_bloc.dart';
import 'package:simple/Bloc/Report/report_bloc.dart';
import 'package:simple/Bloc/ShiftClosing/shift_closing_bloc.dart';
import 'package:simple/Bloc/StockIn/stock_in_bloc.dart';
import 'package:simple/injector/injector.dart';

class BlocModule {
  BlocModule._();

  static void init() {
    final injector = Injector.instance;

    injector
      ..registerFactory<LoginInBloc>(
              () => LoginInBloc(
            authRepository: injector(),
            logService: injector(),
            authService: injector(),

          )
      )
      ..registerFactory<FoodCategoryBloc>(
              () => FoodCategoryBloc(
            categoryRepository: injector(),
            logService: injector(),
          )
      )
      ..registerFactory<OrderTodayBloc>(
              () => OrderTodayBloc(
            orderRepository: injector(),
            logService: injector(),
          )
      )
      ..registerFactory<ProductCategoryBloc>(
              () => ProductCategoryBloc(
            productRepository: injector(),
            logService: injector(),
          )
      )
      ..registerFactory<ReportTodayBloc>(
              () => ReportTodayBloc(
            reportRepository: injector(),
            logService: injector(),
          )
      )
      ..registerFactory<StockInBloc>(
              () => StockInBloc(
            stockInRepository: injector(),
            logService: injector(),
          )
      )
      ..registerFactory<ShiftClosingBloc>(
              () => ShiftClosingBloc(
            shiftClosingRepository: injector(),
            logService: injector(),
            orderRepository: injector(),
          )
      );
    //   ..registerFactory<DashboardBloc>(
    //           () => DashboardBloc(
    //         logService: injector(),
    //             commonRepository: injector()
    //
    //
    //       )
    //   )
    //   ..registerFactory<HomeBloc>(
    //           () => HomeBloc(
    //           logService: injector(),
    //           homeRepository: injector()
    //
    //
    //       )
    //   )
    //   ..registerFactory<ExpensesBloc>(
    //           () => ExpensesBloc(
    //           logService: injector(),
    //           expenseRepository: injector(),
    //             commonRepository: injector()
    //
    //
    //       )
    //   )
    //   ..registerFactory<ExpenseCategoryBloc>(
    //           () => ExpenseCategoryBloc(
    //           logService: injector(),
    //           expenseRepository: injector(),
    //           commonRepository: injector()
    //       )
    //   )
    //   ..registerFactory<OrdersBloc>(
    //           () => OrdersBloc(
    //           logService: injector(),
    //           ordersRepository: injector(),
    //       )
    //   )
    //   ..registerFactory<ShiftCloseBloc>(
    //           () => ShiftCloseBloc(
    //         logService: injector(),
    //         repository: injector(),
    //       )
    //   )
    // ;
  }


}