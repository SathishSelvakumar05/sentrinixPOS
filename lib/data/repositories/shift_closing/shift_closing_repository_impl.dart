import 'package:simple/ModelClass/ShiftClosing/getShiftClosingModel.dart';
import 'package:simple/ModelClass/ShiftClosing/postDailyClosingModel.dart';
import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/repositories/shift_closing/shift_closing_repository.dart';

class ShiftClosingRepositoryImpl implements ShiftClosingRepository {
  final ApiClient _apiClient;

  ShiftClosingRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<GetShiftClosingModel> getShiftClosing(String date) async {
    return await _apiClient.getShiftClosing(date);
  }

  @override
  Future<PostDailyClosingModel> postDailyClosing(Map<String, dynamic> payload) async {
    return await _apiClient.postDailyClosing(payload);
  }
}
