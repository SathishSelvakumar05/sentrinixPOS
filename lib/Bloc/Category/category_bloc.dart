import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple/UI/Home_screen/home_screen.dart';
import 'package:simple/UI/Home_screen/Helper/order_type.dart';
import 'package:simple/data/repositories/category/category_repository.dart';
import 'package:simple/services/log_service/log_service.dart';
import 'package:simple/injector/injector.dart';

abstract class FoodCategoryEvent {}

class FoodCategory extends FoodCategoryEvent {}

class FoodProductItem extends FoodCategoryEvent {
  String catId;
  String searchKey;
  String searchCode;
  FoodProductItem(this.catId, this.searchKey, this.searchCode);
}
class AddToBilling extends FoodCategoryEvent {
  List<Map<String, dynamic>> billingItems;
  bool isDiscount;
  OrderType? orderType;
  final bool? isEditingOrder;
  final String? orderId;
  AddToBilling(this.billingItems, this.isDiscount, this.orderType,
      {this.isEditingOrder, this.orderId});
}

class GenerateOrder extends FoodCategoryEvent {
  final String orderPayloadJson;
  GenerateOrder(this.orderPayloadJson);
}

class GenerateRazorPayOrder extends FoodCategoryEvent {
  final String orderPayloadJson;
  GenerateRazorPayOrder(this.orderPayloadJson);
}

class UpdateOrder extends FoodCategoryEvent {
  final String orderPayloadJson;
  String? orderId;
  UpdateOrder(this.orderPayloadJson, this.orderId);
}

class TableDine extends FoodCategoryEvent {}

class WaiterDine extends FoodCategoryEvent {}

class StockDetails extends FoodCategoryEvent {}

class FetchCompanyCurrent extends FoodCategoryEvent {}

class FoodCategoryBloc extends Bloc<FoodCategoryEvent, dynamic> {
  final CategoryRepository _categoryRepository;
  final LogService _logService;
  static const String tag = 'FoodCategoryBloc';
  String orderPayLoad = '';

  FoodCategoryBloc({
    CategoryRepository? categoryRepository,
    LogService? logService,
  })  : _categoryRepository = categoryRepository ?? injector<CategoryRepository>(),
        _logService = logService ?? injector<LogService>(),
        super(null) {
    on<FoodCategory>(_onFoodCategory);
    on<FoodProductItem>(_onFoodProductItem);
    on<AddToBilling>(_onAddToBilling);
    on<GenerateOrder>(_onGenerateOrder);
    on<GenerateRazorPayOrder>(_onGenerateRazorPayOrder);
    on<UpdateOrder>(_onUpdateOrder);
    on<TableDine>(_onTableDine);
    on<WaiterDine>(_onWaiterDine);
    on<StockDetails>(_onStockDetails);
    on<FetchCompanyCurrent>(_onFetchCompanyCurrent);
  }

  Future<void> _onFoodCategory(
      FoodCategory event, Emitter<dynamic> emit) async {
    try {
      final response = await _categoryRepository.getCategory();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag FoodCategory error", e, s);
      emit(e);
    }
  }

  Future<void> _onFoodProductItem(
      FoodProductItem event, Emitter<dynamic> emit) async {
    try {
      final response = await _categoryRepository.getProductItem(
          event.catId, event.searchKey, event.searchCode);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag FoodProductItem error", e, s);
      emit(e);
    }
  }

  Future<void> _onAddToBilling(
      AddToBilling event, Emitter<dynamic> emit) async {
    try {
      final response = await _categoryRepository.addToBilling(
        event.billingItems,
        event.isDiscount,
        event.orderType?.apiValue,
        isEditingOrder: event.isEditingOrder,
        orderId: event.orderId,
      );
      emit(response);
    } catch (e, s) {
      _logService.e("$tag AddToBilling error", e, s);
      emit(e);
    }
  }

  Future<void> _onGenerateOrder(
      GenerateOrder event, Emitter<dynamic> emit) async {
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

      final response =
          await _categoryRepository.generateOrder(event.orderPayloadJson);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag GenerateOrder error", e, s);
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
        "amount": payLoad['total'],
        "receipt": "rcpt_${DateTime.now().millisecondsSinceEpoch}",
        "notes": {"orderType": payLoad['orderType'], "tableNo": payLoad['tableNo'] ?? "N/A"}
      };

      final response =
          await _categoryRepository.generateRazorPayOrder(jsonEncode(request));
      _logService.i("$tag GenerateRazorPayOrder response: $response");
      emit(response);
    } catch (e, s) {
      _logService.e("$tag GenerateRazorPayOrder error", e, s);
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

      final response = await _categoryRepository.updateOrder(
          event.orderPayloadJson, event.orderId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag UpdateOrder error", e, s);
      emit(e);
    }
  }

  Future<void> _onTableDine(TableDine event, Emitter<dynamic> emit) async {
    try {
      final response = await _categoryRepository.getTable();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag TableDine error", e, s);
      emit(e);
    }
  }

  Future<void> _onWaiterDine(WaiterDine event, Emitter<dynamic> emit) async {
    try {
      final response = await _categoryRepository.getWaiter();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag WaiterDine error", e, s);
      emit(e);
    }
  }

  Future<void> _onStockDetails(
      StockDetails event, Emitter<dynamic> emit) async {
    try {
      final response = await _categoryRepository.getStockDetails();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag StockDetails error", e, s);
      emit(e);
    }
  }

  Future<void> _onFetchCompanyCurrent(
      FetchCompanyCurrent event, Emitter<dynamic> emit) async {
    try {
      final response = await _categoryRepository.getCompanyCurrent();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag FetchCompanyCurrent error", e, s);
      emit(e);
    }
  }
}
