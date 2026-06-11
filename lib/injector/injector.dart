import 'package:get_it/get_it.dart';
import 'package:simple/injector/module/api_client_module.dart';
import 'package:simple/injector/module/bloc_module.dart';
import 'package:simple/injector/module/dio_client_module.dart';
import 'package:simple/injector/module/repository_module.dart';
import 'package:simple/injector/module/service_module.dart';

class Injector {
  Injector._();

  static GetIt instance = GetIt.instance;

  static void init() {
    ServiceModule.init();
    DioClientModule.setup();
    ApiClientModule.init();
    RepositoryModule.init();
    BlocModule.init();
  }

  static void reset() {
    instance.reset();
  }

  static void resetLazySingleton() {
    instance.resetLazySingleton();
  }

}

final injector = Injector.instance;