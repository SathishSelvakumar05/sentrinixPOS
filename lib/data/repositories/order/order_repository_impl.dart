import 'package:simple/ModelClass/Order/Delete_order_model.dart';
import 'package:simple/ModelClass/Order/Get_view_order_model.dart';
import 'package:simple/ModelClass/Order/Update_generate_order_model.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';
import 'package:simple/ModelClass/Order/get_order_list_today_model.dart';
import 'package:simple/ModelClass/RazorPayOrderResponseModel.dart';
import 'package:simple/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/User/getUserModel.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/repositories/order/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  late final ApiClient _apiClient;

  @override
  Future<GetOrderListTodayModel> getOrderToday(
      String? fromDate,
      String? toDate,
      String? tableId,
      String? waiterId,
      String? operator) async {
    return await _apiClient.getOrderToday(
        fromDate, toDate, tableId, waiterId, operator);
  }

  @override
  Future<DeleteOrderModel> deleteOrder(String? orderId) async {
    return await _apiClient.deleteOrder(orderId);
  }

  @override
  Future<GetLocationDetailsModel> getLocationDetails() {
    return _apiClient.getLocationDetails();
  }

  @override
  Future<GetViewOrderModel> viewOrder(String? orderId) async {
    return await _apiClient.viewOrder(orderId);
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
  Future<GetUserModel> getUserDetails() async {
    return await _apiClient.getUserDetails();
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
  Future<UpdateGenerateOrderModel> updateOrder(
      String orderPayloadJson, String? orderId) async {
    return await _apiClient.updateGenerateOrder(orderPayloadJson, orderId);
  }
  @override
  Future<GetCompanyModel> getCompanyCurrent() async {
    return await _apiClient.getCompanyCurrent();
  }
}
