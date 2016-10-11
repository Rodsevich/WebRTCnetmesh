import 'dart:async';
import 'dart:io';

const String defaultHost = 'localhost';
const int defaultPort = 4040;

main() => Server.run(dumpOutput: true);

WebSocket controlador;
WebSocket servidor;

class Server {
  static Future run(
      {bool dumpOutput: false,
      String host: defaultHost,
      int port: defaultPort}) {
    Server server = new Server(host: host, port: port);
    server.output.listen(print);
    return server.start();
  }

  final String host;
  final int port;

  Logger _logger = new Logger();
  HttpServer _server;
  StreamSubscription _subscription;

  Server({this.host: defaultHost, this.port: defaultPort});

  Stream get output => _logger.stream;

  Future start() async {
    try {
      _server = await HttpServer.bind(host, port);
      _subscription = _server.listen((request) async {
        try {
          _logger.logRequest(request);
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            WebSocketTransformer.upgrade(request).then((ws) {
              if (controlador == null) {
                controlador = ws;
                controlador.listen(entradaControlador);
                print("controlador conectado");
              } else {
                servidor = ws;
                servidor.listen(entradaServidor);
                controlador.add("hay conexion");
                print("servidor conectado");
              }
            });
          }
        } catch (e, stackTrace) {
          _logger.logError(e, stackTrace);
        }
      });

      _logger('HTTP server ready - listening on http://$host:$port');
    } catch (e) {
      print('Failed to start HTTP server - port $port may already be taken.');
      _logger.logError(
          'Failed to start HTTP server - port $port may already be taken.');
      exit(1);
    }
  }

  Future stop() async {
    await Future.wait(
        [_server.close(force: true), _subscription.cancel(), _logger.close()]);
  }
}

void entradaServidor(event) {
  controlador.add(event);
}

void entradaControlador(event) {
  if (servidor != null) {
    servidor.add(event);
  }
}

// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

class Logger implements Function {
  StreamController<String> _controller = new StreamController();

  Logger();

  Stream get stream => _controller.stream;

  void call(String message, [bool isError = false]) {
    if (isError) {
      _controller.add('[ERROR] $message');
    } else {
      _controller.add('$message');
    }
  }

  Future close() {
    return _controller.close();
  }

  void logError(error, [StackTrace stackTrace]) {
    var e = stackTrace != null ? '$error\n$stackTrace' : '$error';
    this(e, true);
  }

  void logRequest(HttpRequest request) {
    DateTime time = new DateTime.now();
    this(
        '$time\t${request.method}\t${request.response.statusCode}\t${request.uri.path}');
  }

  void withTime(String msg, [bool isError = false]) {
    this('${new DateTime.now()}  $msg', isError);
  }
}
