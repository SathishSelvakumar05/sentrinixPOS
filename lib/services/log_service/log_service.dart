abstract class LogService {
  void d(String message);
  void e(String message, dynamic e, StackTrace? stack);
  void i(String message);
  void w(String message, [dynamic e, StackTrace? stack]);
}
