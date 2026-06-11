import 'package:simple/ModelClass/Report/Get_report_with_ordertype_model.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/User/getUserModel.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';

abstract class ReportRepository {
  Future<GetReportModel> getReportToday(String? fromDate, String? toDate,
      String? tableId, String? waiterId, String? operatorId);
  Future<GetTableModel> getTable();
  Future<GetWaiterModel> getWaiter();
  Future<GetUserModel> getUserDetails();
  Future<GetCompanyModel> getCompanyCurrent();
  Future<GetLocationDetailsModel> getLocationDetails();
}
