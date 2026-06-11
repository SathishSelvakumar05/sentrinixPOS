import 'package:simple/ModelClass/Report/Get_report_with_ordertype_model.dart';
import 'package:simple/ModelClass/Table/Get_table_model.dart';
import 'package:simple/ModelClass/User/getUserModel.dart';
import 'package:simple/ModelClass/Waiter/getWaiterModel.dart';
import 'package:simple/ModelClass/Company/getCompanyModel.dart';
import 'package:simple/ModelClass/Location/get_location_details_model.dart';
import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/repositories/report/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;
  late final ApiClient _apiClient;

  @override
  Future<GetReportModel> getReportToday(String? fromDate, String? toDate,
      String? tableId, String? waiterId, String? operatorId) async {
    return await _apiClient.getReportToday(
        fromDate, toDate, tableId, waiterId, operatorId);
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
  Future<GetCompanyModel> getCompanyCurrent() async {
    return await _apiClient.getCompanyCurrent();
  }

  @override
  Future<GetLocationDetailsModel> getLocationDetails() async {
    return await _apiClient.getLocationDetails();
  }
}
