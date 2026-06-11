import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple/Api/apiProvider.dart';

abstract class ExpenseEvent {}

class StockInLocation extends ExpenseEvent {}

class CategoryByLocation extends ExpenseEvent {
  String locationId;
  CategoryByLocation(this.locationId);
}

class SaveExpense extends ExpenseEvent {
  String date;
  String catId;
  String name;
  String method;
  String amount;
  String locId;
  SaveExpense(
      this.date, this.catId, this.name, this.method, this.amount, this.locId);
}

class DailyExpense extends ExpenseEvent {
  String search;
  String locId;
  String catId;
  String payMethod;
  DailyExpense(this.search, this.locId, this.catId, this.payMethod);
}

class ExpenseById extends ExpenseEvent {
  String expenseId;
  ExpenseById(this.expenseId);
}

class UpdateExpense extends ExpenseEvent {
  String expenseId;
  String date;
  String catId;
  String name;
  String method;
  String amount;
  String locId;
  UpdateExpense(this.expenseId, this.date, this.catId, this.name, this.method,
      this.amount, this.locId);
}

class ExpenseBloc extends Bloc<ExpenseEvent, dynamic> {
  ExpenseBloc() : super(null) {
    on<StockInLocation>((event, emit) async {
      await ApiProvider().getLocationAPI().then((value) {
        emit(value);
      }).catchError((error) {
        emit(error);
      });
    });
    on<CategoryByLocation>((event, emit) async {
      // await ApiProvider()
      //     .getCategoryByLocationAPI(event.locationId)
      //     .then((value) {
      //   emit(value);
      // }).catchError((error) {
      //   emit(error);
      // });
    });
    on<SaveExpense>((event, emit) async {
      // await ApiProvider()
      //     .postExpenseAPI(event.date, event.catId, event.name, event.method,
      //         event.amount, event.locId)
      //     .then((value) {
      //   emit(value);
      // }).catchError((error) {
      //   emit(error);
      // });
    });
    on<DailyExpense>((event, emit) async {
      // await ApiProvider()
      //     .getDailyExpenseAPI(
      //         event.search, event.locId, event.catId, event.payMethod)
      //     .then((value) {
      //   emit(value);
      // }).catchError((error) {
      //   emit(error);
      // });
    });
    on<ExpenseById>((event, emit) async {
      // await ApiProvider().getSingleExpenseAPI(event.expenseId).then((value) {
      //   emit(value);
      // }).catchError((error) {
      //   emit(error);
      // });
    });
    on<UpdateExpense>((event, emit) async {
      // await ApiProvider()
      //     .putExpenseAPI(event.expenseId, event.date, event.catId, event.name,
      //         event.method, event.amount, event.locId)
      //     .then((value) {
      //   emit(value);
      // }).catchError((error) {
      //   emit(error);
      // });
    });
  }
}
