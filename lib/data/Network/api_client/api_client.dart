import 'package:dio/dio.dart';
import 'package:simple/ModelClass/Authentication/Post_login_model.dart';
import 'package:simple/ModelClass/Cart/Post_Add_to_billing_model.dart';
import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_category_model.dart';
import 'package:simple/ModelClass/HomeScreen/Category&Product/Get_product_by_catId_model.dart';
import 'package:simple/ModelClass/Order/Delete_order_model.dart';
import 'package:simple/ModelClass/Order/Get_view_order_model.dart';
import 'package:simple/ModelClass/Order/Post_generate_order_model.dart';
import 'package:simple/ModelClass/Order/Update_generate_order_model.dart';
import 'package:simple/ModelClass/Order/get_order_list_today_model.dart';
import 'package:simple/ModelClass/Products/get_products_cat_model.dart';
import 'package:simple/ModelClass/Report/Get_report_with_ordertype_model.dart';
import 'package:simple/ModelClass/ShiftClosing/getShiftClosingModel.dart';
import 'package:simple/ModelClass/ShiftClosing/postDailyClosingModel.dart';
import 'package:simple/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:simple/ModelClass/StockIn/getLocationModel.dart';
import 'package:simple/ModelClass/StockIn/getSupplierLocationModel.dart';
import 'package:simple/ModelClass/StockIn/get_add_product_model.dart';
import 'package:simple/ModelClass/StockIn/saveStockInModel.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/User/getUserModel.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/ModelClass/RazorPayOrderResponseModel.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';
import 'package:simple/utilies/exceptions/app_exception.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<GetCompanyModel> getCompanyCurrent() async {
    return await get("api/company/current",
        fromJson: (data) => GetCompanyModel.fromJson(data)).onApiError;
  }

  Future<PostLoginModel> loginUser(Map<String, String> payLoad) async {
    return await post("auth/users/login", data: payLoad,
        fromJson: (data) => PostLoginModel.fromJson(data)).onApiError;
  }

  Future<GetCategoryModel> getCategory() async {
    return await get("api/categories/name",
        fromJson: (data) => GetCategoryModel.fromJson(data)).onApiError;
  }

  Future<GetProductByCatIdModel> getProductItem(String? catId, String? searchKey, String? searchCode) async {
    return await get("api/products/pos/category-products?filter=false&categoryId=$catId&search=$searchKey&searchcode=$searchCode",
        fromJson: (data) => GetProductByCatIdModel.fromJson(data)).onApiError;
  }

  Future<GetProductsCatModel> getProductsCat(String? catId) async {
    return await get(
        "api/products/pos/category-products-with-category?filter=false&categoryId=$catId",
        fromJson: (data) => GetProductsCatModel.fromJson(data)).onApiError;
  }

  Future<PostAddToBillingModel> postAddToBilling(
      List<Map<String, dynamic>> billingItems,
      bool? isDiscount,
      String? orderType,
      {bool? isEditingOrder,
      String? orderId}) async {
    final mappedItems = billingItems.map((item) {
      final mappedItem = Map<String, dynamic>.from(item);
      if (mappedItem.containsKey('_id')) mappedItem['product'] = mappedItem['_id'];
      if (mappedItem.containsKey('qty')) mappedItem['quantity'] = mappedItem['qty'];
      if (mappedItem.containsKey('basePrice')) mappedItem['unitPrice'] = mappedItem['basePrice'];
      
      if (mappedItem['selectedAddons'] != null) {
         mappedItem['addons'] = (mappedItem['selectedAddons'] as List).map((addon) {
            final mappedAddon = Map<String, dynamic>.from(addon);
            if (mappedAddon.containsKey('_id')) mappedAddon['addon'] = mappedAddon['_id'];
            return mappedAddon;
         }).toList();
      }
      return mappedItem;
    }).toList();

    final dataMap = {
      "items": mappedItems,
      "isApplicableDiscount": isDiscount,
      "orderType": orderType,
      "isEditingOrder": isEditingOrder ?? false,
      "orderId": orderId
    };
    return await post("api/generate-order/billing/calculate",
        data: dataMap,
        fromJson: (data) => PostAddToBillingModel.fromJson(data)).onApiError;
  }

  Future<PostGenerateOrderModel> postGenerateOrder(
      String orderPayloadJson) async {
    return await post("api/generate-order/order",
        data: orderPayloadJson,
        fromJson: (data) => PostGenerateOrderModel.fromJson(data)).onApiError;
  }

  Future<UpdateGenerateOrderModel> updateGenerateOrder(
      String orderPayloadJson, String? orderId) async {
    return await put("api/generate-order/order/$orderId",
        data: orderPayloadJson,
        fromJson: (data) => UpdateGenerateOrderModel.fromJson(data)).onApiError;
  }

  Future<GetLocationDetailsModel> getLocationDetails() async {
    return await get("api/location",
        fromJson: (data) => GetLocationDetailsModel.fromJson(data)).onApiError;
  }

  Future<GetOrderListTodayModel> getOrderToday(
      String? fromDate,
      String? toDate,
      String? tableId,
      String? waiterId,
      String? operator) async {
    return await get(
        "api/generate-order?from_date=$fromDate&to_date=$toDate&tableNo=$tableId&waiter=$waiterId&operator=$operator",
        fromJson: (data) => GetOrderListTodayModel.fromJson(data)).onApiError;
  }

  Future<GetReportModel> getReportToday(String? fromDate, String? toDate,
      String? tableId, String? waiterId, String? operatorId) async {
    return await get(
        "api/generate-order/sales-reportwithordertype?from_date=$fromDate&to_date=$toDate&limit=200&tableNo=$tableId&waiter=$waiterId&operator=$operatorId",
        fromJson: (data) => GetReportModel.fromJson(data)).onApiError;
  }

  Future<DeleteOrderModel> deleteOrder(String? orderId) async {
    return await delete("api/generate-order/order/$orderId",
        fromJson: (data) => DeleteOrderModel.fromJson(data)).onApiError;
  }

  Future<GetViewOrderModel> viewOrder(String? orderId) async {
    return await get("api/generate-order/$orderId",
        fromJson: (data) => GetViewOrderModel.fromJson(data)).onApiError;
  }

  Future<GetUserModel> getUserDetails() async {
    return await get("auth/users",
        fromJson: (data) => GetUserModel.fromJson(data)).onApiError;
  }

  Future<GetTableModel> getTable() async {
    return await get("api/tables",
        fromJson: (data) => GetTableModel.fromJson(data)).onApiError;
  }

  Future<GetWaiterModel> getWaiter() async {
    return await get("api/waiter",
        fromJson: (data) => GetWaiterModel.fromJson(data)).onApiError;
  }

  Future<GetStockMaintanencesModel> getStockDetails() async {
    return await get("api/shops",
        fromJson: (data) => GetStockMaintanencesModel.fromJson(data)).onApiError;
  }

  Future<GetLocationModel> getLocation() async {
    return await get("auth/users/bylocation",
        fromJson: (data) => GetLocationModel.fromJson(data)).onApiError;
  }

  Future<GetSupplierLocationModel> getSupplier(String? locationId) async {
    return await get(
        "api/supplier?isDefault=true&filter=false&locationId=$locationId",
        fromJson: (data) => GetSupplierLocationModel.fromJson(data)).onApiError;
  }

  Future<GetAddProductModel> getAddProduct(String? locationId) async {
    return await get("api/products?locationId=$locationId",
        fromJson: (data) => GetAddProductModel.fromJson(data)).onApiError;
  }

  Future<SaveStockInModel> postSaveStockIn(String stockInPayloadJson) async {
    return await post("api/stock",
        data: stockInPayloadJson,
        fromJson: (data) => SaveStockInModel.fromJson(data)).onApiError;
  }

  Future<GetShiftClosingModel> getShiftClosing(String date) async {
    return await get("api/daily-closing?date=$date",
        fromJson: (data) => GetShiftClosingModel.fromJson(data)).onApiError;
  }

  Future<PostDailyClosingModel> postDailyClosing(Map<String, dynamic> payload) async {
    return await post("api/daily-closing",
        data: payload,
        fromJson: (data) => PostDailyClosingModel.fromJson(data)).onApiError;
  }

  Future<RazorPayOrderResponseModel> razorPayCreateOrder(
      String orderPayloadJson) async {
    return await post("api/razorpay/create-order",
        data: orderPayloadJson,
        fromJson: (data) => RazorPayOrderResponseModel.fromJson(data)).onApiError;
  }

  Future<PostGenerateOrderModel> razorPayVerifyPayment(
      Map<String, dynamic> payload) async {
    return await post("api/razorpay/verify-payment",
        data: payload,
        fromJson: (data) => PostGenerateOrderModel.fromJson(data)).onApiError;
  }

  Future<T> get<T>(
      String path, {
        Map<String, dynamic>? queryParams,
        required T Function(dynamic data) fromJson,
      }) async {
    final response = await _dio
        .get(path, queryParameters: queryParams).onApiError;

    return fromJson(response.data);
  }

  Future<T> post<T>(
      String path, {
        dynamic data,
        required T Function(dynamic data) fromJson,
      }) async {
    final response = await _dio
        .post(path, data: data)
        .onApiError;

    return fromJson(response.data);
  }

  Future<T> put<T>(
      String path, {
        dynamic data,
        required T Function(dynamic data) fromJson,
      }) async {
    final response = await _dio
        .put(path, data: data)
        .onApiError;

    return fromJson(response.data);
  }

  Future<T> delete<T>(
      String path, {
        Map<String, dynamic>? queryParams,
        required T Function(dynamic data) fromJson,
      }) async {
    final response = await _dio
        .delete(path, queryParameters: queryParams)
        .onApiError;

    return fromJson(response.data);
  }
}
