import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple/data/repositories/stock_in/stock_in_repository.dart';
import 'package:simple/services/log_service/log_service.dart';
import 'package:simple/injector/injector.dart';

abstract class StockInEvent {}

class StockInLocation extends StockInEvent {}

class StockInSupplier extends StockInEvent {
  String locationId;
  StockInSupplier(this.locationId);
}

class StockInAddProduct extends StockInEvent {
  String locationId;
  StockInAddProduct(this.locationId);
}

class SaveStockIn extends StockInEvent {
  final String orderPayloadJson;
  SaveStockIn(this.orderPayloadJson);
}

class StockInBloc extends Bloc<StockInEvent, dynamic> {
  final StockInRepository _stockInRepository;
  final LogService _logService;
  static const String tag = 'StockInBloc';

  StockInBloc({
    StockInRepository? stockInRepository,
    LogService? logService,
  })  : _stockInRepository = stockInRepository ?? injector<StockInRepository>(),
        _logService = logService ?? injector<LogService>(),
        super(null) {
    on<StockInLocation>(_onStockInLocation);
    on<StockInSupplier>(_onStockInSupplier);
    on<StockInAddProduct>(_onStockInAddProduct);
    on<SaveStockIn>(_onSaveStockIn);
  }

  Future<void> _onStockInLocation(
      StockInLocation event, Emitter<dynamic> emit) async {
    try {
      final response = await _stockInRepository.getLocation();
      emit(response);
    } catch (e, s) {
      _logService.e("$tag StockInLocation error", e, s);
      emit(e);
    }
  }

  Future<void> _onStockInSupplier(
      StockInSupplier event, Emitter<dynamic> emit) async {
    try {
      final response = await _stockInRepository.getSupplier(event.locationId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag StockInSupplier error", e, s);
      emit(e);
    }
  }

  Future<void> _onStockInAddProduct(
      StockInAddProduct event, Emitter<dynamic> emit) async {
    try {
      final response = await _stockInRepository.getAddProduct(event.locationId);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag StockInAddProduct error", e, s);
      emit(e);
    }
  }

  Future<void> _onSaveStockIn(SaveStockIn event, Emitter<dynamic> emit) async {
    try {
      final response =
          await _stockInRepository.postSaveStockIn(event.orderPayloadJson);
      emit(response);
    } catch (e, s) {
      _logService.e("$tag SaveStockIn error", e, s);
      emit(e);
    }
  }
}
