import 'package:simple/ModelClass/Cart/Post_Add_to_billing_model.dart';
import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_category_model.dart';
import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_product_by_catId_model.dart';
import 'package:simple/ModelClass/Order/Post_generate_order_model.dart';
import 'package:simple/ModelClass/Order/Update_generate_order_model.dart';
import 'package:simple/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/ModelClass/RazorPayOrderResponseModel.dart';

abstract class CategoryRepository {
  Future<GetCompanyModel> getCompanyCurrent();
  Future<GetCategoryModel> getCategory();
  Future<GetProductByCatIdModel> getProductItem(
      String catId, String searchKey, String searchCode);
  Future<PostAddToBillingModel> addToBilling(
      List<Map<String, dynamic>> billingItems,
      bool? isDiscount,
      String? orderType,
      {bool? isEditingOrder,
      String? orderId});
  Future<PostGenerateOrderModel> generateOrder(String orderPayloadJson);
  Future<UpdateGenerateOrderModel> updateOrder(
      String orderPayloadJson, String? orderId);
  Future<GetTableModel> getTable();
  Future<GetWaiterModel> getWaiter();
  Future<GetStockMaintanencesModel> getStockDetails();

  Future<RazorPayOrderResponseModel> generateRazorPayOrder(String orderPayloadJson);
  Future<PostGenerateOrderModel> verifyRazorPayPayment(Map<String, dynamic> payload);
}
