import 'package:simple/ModelClass/Order/Delete_order_model.dart';
import 'package:simple/ModelClass/Order/Get_view_order_model.dart';
import 'package:simple/ModelClass/Order/Update_generate_order_model.dart';
import 'package:simple/ModelClass/Order/get_order_list_today_model.dart';
import 'package:simple/ModelClass/RazorPayOrderResponseModel.dart';
import 'package:simple/ModelClass/ShopDetails/getStockMaintanencesModel.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/User/getUserModel.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';

abstract class OrderRepository {
  Future<GetOrderListTodayModel> getOrderToday(
      String? fromDate,
      String? toDate,
      String? tableId,
      String? waiterId,
      String? operator);
  Future<DeleteOrderModel> deleteOrder(String? orderId);
  Future<GetLocationDetailsModel> getLocationDetails();
  Future<GetViewOrderModel> viewOrder(String? orderId);
  Future<GetTableModel> getTable();
  Future<GetWaiterModel> getWaiter();
  Future<GetUserModel> getUserDetails();
  Future<GetStockMaintanencesModel> getStockDetails();
  Future<RazorPayOrderResponseModel> generateRazorPayOrder(String orderPayloadJson);
  Future<UpdateGenerateOrderModel> updateOrder(
      String orderPayloadJson, String? orderId);
  Future<GetCompanyModel> getCompanyCurrent();
}
