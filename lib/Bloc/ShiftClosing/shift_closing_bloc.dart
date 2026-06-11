import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple/data/repositories/shift_closing/shift_closing_repository.dart';
import 'package:simple/data/repositories/order/order_repository.dart';
import 'package:simple/services/log_service/log_service.dart';
import 'package:simple/injector/injector.dart';

abstract class ShiftClosingEvent {}

class ShiftClosing extends ShiftClosingEvent {
  final String date;
  ShiftClosing(this.date);
}

class SaveShiftClosing extends ShiftClosingEvent {
  final String date;
  final String upiAmount;
  final String enteredUpiAmount;
  final String cardAmount;
  final String enteredCardAmount;
  final String hdAmount;
  final String enteredHdAmount;
  final String totalCashAmount;
  final String cashInHandAmount;
  final String enteredCashInHandAmount;
  final String expectedCashAmount;
  final String totalSalesAmount;
  final String totalExpensesAmount;
  final String overallExpensesAmount;
  final String differenceAmount;

  SaveShiftClosing(
      this.date,
      this.upiAmount,
      this.enteredUpiAmount,
      this.cardAmount,
      this.enteredCardAmount,
      this.hdAmount,
      this.enteredHdAmount,
      this.totalCashAmount,
      this.cashInHandAmount,
      this.enteredCashInHandAmount,
      this.expectedCashAmount,
      this.totalSalesAmount,
      this.totalExpensesAmount,
      this.overallExpensesAmount,
      this.differenceAmount);
}

class StockDetails extends ShiftClosingEvent {}

class ShiftClosingBloc extends Bloc<ShiftClosingEvent, dynamic> {
  final ShiftClosingRepository _shiftClosingRepository;
  final OrderRepository _orderRepository;
  final LogService _logService;
  static const String tag = 'ShiftClosingBloc';

  ShiftClosingBloc({
    ShiftClosingRepository? shiftClosingRepository,
    OrderRepository? orderRepository,
    LogService? logService,
  })  : _shiftClosingRepository = shiftClosingRepository ?? injector<ShiftClosingRepository>(),
        _orderRepository = orderRepository ?? injector<OrderRepository>(),
        _logService = logService ?? injector<LogService>(),
        super(null) {
    on<ShiftClosing>(_onShiftClosing);
    on<SaveShiftClosing>(_onSaveShiftClosing);
    on<StockDetails>(_onStockDetails);
  }

  Future<void> _onShiftClosing(ShiftClosing event, Emitter<dynamic> emit) async {
    try {
      final response = await _shiftClosingRepository.getShiftClosing(event.date);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag ShiftClosing error", e, s);
      emit(e);
    }
  }

  Future<void> _onSaveShiftClosing(SaveShiftClosing event, Emitter<dynamic> emit) async {
    try {
      final payload = {
        "date": event.date,
        "upi_amount": event.upiAmount,
        "entered_upi_amount": event.enteredUpiAmount,
        "card_amount": event.cardAmount,
        "entered_card_amount": event.enteredCardAmount,
        "hd_amount": event.hdAmount,
        "entered_hd_amount": event.enteredHdAmount,
        "total_cash_amount": event.totalCashAmount,
        "cash_in_hand_amount": event.cashInHandAmount,
        "entered_cash_in_hand_amount": event.enteredCashInHandAmount,
        "expected_cash_amount": event.expectedCashAmount,
        "total_sales_amount": event.totalSalesAmount,
        "total_expenses_amount": event.totalExpensesAmount,
        "overall_expenses_amount": event.overallExpensesAmount,
        "difference_amount": event.differenceAmount,
      };
      final response = await _shiftClosingRepository.postDailyClosing(payload);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag SaveShiftClosing error", e, s);
      emit(e);
    }
  }

  Future<void> _onStockDetails(StockDetails event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getStockDetails();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag StockDetails error", e, s);
      emit(e);
    }
  }
}
