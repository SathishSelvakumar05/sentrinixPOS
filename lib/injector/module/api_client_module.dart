import 'package:simple/data/Network/api_client/api_client.dart';
import 'package:simple/data/Network/dio_clients/dio_client.dart';
import 'package:simple/injector/injector.dart';

class ApiClientModule {
  ApiClientModule._();

  static void init() {
    final injector = Injector.instance;

    injector
        .registerFactory<ApiClient>(
          () => ApiClient(
        injector(instanceName: DioClient.dioInstanceName),
      ),
    );
    /*  ..registerFactory<SearchApiClient>(
          () => SearchApiClient(
        injector(instanceName: SearchDioModule.dioInstanceName),
      ),
    )..registerFactory<CdnApiClient>(
          () => CdnApiClient(
        injector(instanceName: CdnDioModule.dioInstanceName),
      ),
    );*/
  }
}