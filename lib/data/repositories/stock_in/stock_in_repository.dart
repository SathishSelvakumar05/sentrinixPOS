import 'package:simple/ModelClass/StockIn/getLocationModel.dart';
import 'package:simple/ModelClass/StockIn/getSupplierLocationModel.dart';
import 'package:simple/ModelClass/StockIn/get_add_product_model.dart';
import 'package:simple/ModelClass/StockIn/saveStockInModel.dart';

abstract class StockInRepository {
  Future<GetLocationModel> getLocation();
  Future<GetSupplierLocationModel> getSupplier(String? locationId);
  Future<GetAddProductModel> getAddProduct(String? locationId);
  Future<SaveStockInModel> postSaveStockIn(String stockInPayloadJson);
}
