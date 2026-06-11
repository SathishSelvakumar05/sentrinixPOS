import 'package:simple/ModelClass/ShiftClosing/getShiftClosingModel.dart';
import 'package:simple/ModelClass/ShiftClosing/postDailyClosingModel.dart';

abstract class ShiftClosingRepository {
  Future<GetShiftClosingModel> getShiftClosing(String date);
  Future<PostDailyClosingModel> postDailyClosing(Map<String, dynamic> payload);
}
