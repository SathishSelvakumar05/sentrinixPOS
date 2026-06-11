import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple/data/repositories/order/order_repository.dart';
import 'package:simple/services/log_service/log_service.dart';
import 'package:simple/injector/injector.dart';

abstract class OrderTodayEvent {}

class OrderTodayList extends OrderTodayEvent {
  String fromDate;
  String toDate;
  String tableId;
  String waiterId;
  String userId;
  OrderTodayList(
      this.fromDate, this.toDate, this.tableId, this.waiterId, this.userId);
}

class DeleteOrder extends OrderTodayEvent {
  String? orderId;
  DeleteOrder(this.orderId);
}

class ViewOrder extends OrderTodayEvent {
  String? orderId;
  ViewOrder(this.orderId);
}

class TableDine extends OrderTodayEvent {}

class WaiterDine extends OrderTodayEvent {}

class UserDetails extends OrderTodayEvent {}

class StockDetails extends OrderTodayEvent {}
class FetchCompanyCurrent extends OrderTodayEvent {}

class FetchLocationDetails extends OrderTodayEvent {}

class UpdateOrder extends OrderTodayEvent {
  final String orderPayloadJson;
  String? orderId;
  UpdateOrder(this.orderPayloadJson, this.orderId);
}

class GenerateRazorPayOrder extends OrderTodayEvent {
  final String orderPayloadJson;
  GenerateRazorPayOrder(this.orderPayloadJson);
}

class OrderTodayBloc extends Bloc<OrderTodayEvent, dynamic> {
  final OrderRepository _orderRepository;
  final LogService _logService;
  static const String tag = 'OrderTodayBloc';
  String orderPayLoad = '';

  OrderTodayBloc({
    OrderRepository? orderRepository,
    LogService? logService,
  })  : _orderRepository = orderRepository ?? injector<OrderRepository>(),
        _logService = logService ?? injector<LogService>(),
        super(null) {
    on<OrderTodayList>(_onOrderTodayList);
    on<DeleteOrder>(_onDeleteOrder);
    on<ViewOrder>(_onViewOrder);
    on<TableDine>(_onTableDine);
    on<WaiterDine>(_onWaiterDine);
    on<UserDetails>(_onUserDetails);
    on<StockDetails>(_onStockDetails);
    on<UpdateOrder>(_onUpdateOrder);
    on<GenerateRazorPayOrder>(_onGenerateRazorPayOrder);
    on<FetchCompanyCurrent>(_onFetchCompanyCurrent);
    on<FetchLocationDetails>(_onFetchLocationDetails);
  }

  Future<void> _onOrderTodayList(
      OrderTodayList event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getOrderToday(
          event.fromDate, event.toDate, event.tableId, event.waiterId, event.userId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag OrderTodayList error", e, s);
      emit(e);
    }
  }

  Future<void> _onDeleteOrder(DeleteOrder event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.deleteOrder(event.orderId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag DeleteOrder error", e, s);
      emit(e);
    }
  }

  Future<void> _onViewOrder(ViewOrder event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.viewOrder(event.orderId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag ViewOrder error", e, s);
      emit(e);
    }
  }

  Future<void> _onTableDine(TableDine event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getTable();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag TableDine error", e, s);
      emit(e);
    }
  }

  Future<void> _onWaiterDine(WaiterDine event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getWaiter();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag WaiterDine error", e, s);
      emit(e);
    }
  }

  Future<void> _onUserDetails(UserDetails event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getUserDetails();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag UserDetails error", e, s);
      emit(e);
    }
  }

  Future<void> _onStockDetails(
      StockDetails event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getStockDetails();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag StockDetails error", e, s);
      emit(e);
    }
  }

  Future<void> _onUpdateOrder(UpdateOrder event, Emitter<dynamic> emit) async {
    try {
      final payLoad = jsonDecode(event.orderPayloadJson);
      bool isOnline = false;
      if (payLoad['payments'] != null && payLoad['payments'] is List && payLoad['payments'].isNotEmpty) {
        if (payLoad['payments'][0]['method'] == 'ONLINE') {
          isOnline = true;
        }
      }

      if (isOnline) {
        add(GenerateRazorPayOrder(event.orderPayloadJson));
        return;
      }

      final response = await _orderRepository.updateOrder(
          event.orderPayloadJson, event.orderId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag UpdateOrder error", e, s);
      emit(e);
    }
  }

  Future<void> _onGenerateRazorPayOrder(
      GenerateRazorPayOrder event, Emitter<dynamic> emit) async {
    try {
      _logService.d("my generate order: ${event.orderPayloadJson}");
      orderPayLoad = event.orderPayloadJson;
      final payLoad = jsonDecode(event.orderPayloadJson);
      
      final request = {
        "amount": payLoad['total'] ?? payLoad['items']?.fold(0.0, (sum, item) => sum + (item['totalPrice'] ?? 0)),
        "receipt": "rcpt_${DateTime.now().millisecondsSinceEpoch}",
        "notes": {"orderType": payLoad['orderType'] ?? "N/A", "tableNo": payLoad['tableNo'] ?? "N/A"}
      };

      final response =
          await _orderRepository.generateRazorPayOrder(jsonEncode(request));
      _logService.i("$tag GenerateRazorPayOrder response: $response");
      emit(response);
    } catch (e, s) {
      _logService.e("$tag GenerateRazorPayOrder error", e, s);
      emit(e);
    }
  }

  Future<void> _onFetchCompanyCurrent(
      FetchCompanyCurrent event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getCompanyCurrent();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag FetchCompanyCurrent error", e, s);
      emit(e);
    }
  }

  Future<void> _onFetchLocationDetails(
      FetchLocationDetails event, Emitter<dynamic> emit) async {
    try {
      final response = await _orderRepository.getLocationDetails();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag FetchLocationDetails error", e, s);
      emit(e);
    }
  }
}
