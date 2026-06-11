import 'package:simple/ModelClass/Authentication/Post_login_model.dart';

abstract class AuthRepository {
  Future<PostLoginModel> loginUser(Map<String, String> payLoad);

}