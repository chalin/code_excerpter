import 'dart:async';

import 'package:logging/logging.dart';

const Symbol logKey = #buildLog;

final _default = new Logger('package:code_excerpter');

Logger _logger;

Logger get log {
  if(_logger != null) return _logger;
  // Use build logger if there is one:
  _logger = Zone.current[logKey] as Logger;
  if (_logger == null) {
    _logger = _default;
    Logger.root.level = Level.FINE;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.message}');
    });
  }
  return _logger;
}
