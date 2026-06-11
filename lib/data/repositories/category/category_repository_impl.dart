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
import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/repositories/category/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  late final ApiClient _apiClient;

  @override
  Future<GetCompanyModel> getCompanyCurrent() async {
    return await _apiClient.getCompanyCurrent();
  }

  @override
  Future<GetCategoryModel> getCategory() async {
    return await _apiClient.getCategory();
  }

  @override
  Future<GetProductByCatIdModel> getProductItem(
      String catId, String searchKey, String searchCode) async {
    return await _apiClient.getProductItem(catId, searchKey, searchCode);
  }

  @override
  Future<PostAddToBillingModel> addToBilling(
      List<Map<String, dynamic>> billingItems,
      bool? isDiscount,
      String? orderType,
      {bool? isEditingOrder,
      String? orderId}) async {
    return await _apiClient.postAddToBilling(billingItems, isDiscount, orderType,
        isEditingOrder: isEditingOrder, orderId: orderId);
  }

  @override
  Future<PostGenerateOrderModel> generateOrder(String orderPayloadJson) async {
    return await _apiClient.postGenerateOrder(orderPayloadJson);
  }

  @override
  Future<UpdateGenerateOrderModel> updateOrder(
      String orderPayloadJson, String? orderId) async {
    return await _apiClient.updateGenerateOrder(orderPayloadJson, orderId);
  }

  @override
  Future<GetTableModel> getTable() async {
    return await _apiClient.getTable();
  }

  @override
  Future<GetWaiterModel> getWaiter() async {
    return await _apiClient.getWaiter();
  }

  @override
  Future<GetStockMaintanencesModel> getStockDetails() async {
    return await _apiClient.getStockDetails();
  }

  @override
  Future<RazorPayOrderResponseModel> generateRazorPayOrder(String orderPayloadJson) async {
    return await _apiClient.razorPayCreateOrder(orderPayloadJson);
  }

  @override
  Future<PostGenerateOrderModel> verifyRazorPayPayment(Map<String, dynamic> payload) async {
    return await _apiClient.razorPayVerifyPayment(payload);
  }
}
