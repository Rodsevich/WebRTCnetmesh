library tool.dev;

import 'dart:async';
import 'package:dart_dev/dart_dev.dart' show dev, config;
import 'package:dart_dev/util.dart' show reporter;
import 'websocket_server.dart';

main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  // Perform task configuration here as necessary.

  // Available task configurations:
  // config.analyze
  // config.copyLicense
  // config.coverage
  // config.docs
  // config.examples
  // config.format
  config.test
    ..unitTests = ['test/unit/']
    // ..functionalTests = ['test/functional']
    ..integrationTests = ['test/integration/']
    ..before = [_servidor];

  await dev(args);
}

Server _server;

Future _servidor() async {
  _server = new Server();
  _server.output.listen((line) {
    reporter.log(reporter.colorBlue('    $line'));
  });
  await _server.start();
}
