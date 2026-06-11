import 'package:simple/ModelClass/StockIn/getLocationModel.dart';
import 'package:simple/ModelClass/StockIn/getSupplierLocationModel.dart';
import 'package:simple/ModelClass/StockIn/get_add_product_model.dart';
import 'package:simple/ModelClass/StockIn/saveStockInModel.dart';
import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/repositories/stock_in/stock_in_repository.dart';

class StockInRepositoryImpl implements StockInRepository {
  StockInRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  late final ApiClient _apiClient;

  @override
  Future<GetLocationModel> getLocation() async {
    return await _apiClient.getLocation();
  }

  @override
  Future<GetSupplierLocationModel> getSupplier(String? locationId) async {
    return await _apiClient.getSupplier(locationId);
  }

  @override
  Future<GetAddProductModel> getAddProduct(String? locationId) async {
    return await _apiClient.getAddProduct(locationId);
  }

  @override
  Future<SaveStockInModel> postSaveStockIn(String stockInPayloadJson) async {
    return await _apiClient.postSaveStockIn(stockInPayloadJson);
  }
}
