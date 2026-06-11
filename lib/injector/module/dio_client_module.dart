import 'package:simple/data/Network/dio_clients/dio_client.dart';

class DioClientModule {
  DioClientModule._();

  static void setup() {
    DioClient.setup();
  }


}