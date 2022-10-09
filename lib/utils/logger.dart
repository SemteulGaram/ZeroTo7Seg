// 전역적으로 사용할 로거
class Logger {
  static final Logger _instance = Logger._internal();

  factory Logger() {
    return _instance;
  }

  Logger._internal();

  void info(Object? message) {
    // ignore: avoid_print
    print(message);
  }

  void error(Object? message) {
    // ignore: avoid_print
    print(message);
  }
}
