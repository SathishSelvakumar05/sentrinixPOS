import 'package:simple/injector/injector.dart';
import 'package:simple/services/auth_service/auth_service.dart';
import 'package:simple/services/auth_service/auth_service_impl.dart';
import 'package:simple/services/log_service/debug_log_service.dart';
import 'package:simple/services/log_service/log_service.dart';

class ServiceModule {
  ServiceModule._();

  static void init() {
    final injector = Injector.instance;

    injector
      ..registerFactory<LogService>(DebugLogService.new)
      ..registerLazySingleton<AuthService>(
              ()=>AuthServiceImpl()
      )
    // ..registerLazySingleton<UserService>(
    //         ()=>UserServiceImpl()
    // )

        ;
  }
}