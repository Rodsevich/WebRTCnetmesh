# WebRTCnetmesh

A library for interconnecting several browsers through WebRTC via websockets.

## Usage

A simple usage example:

    import 'package:WebRTCnetmesh/WebRTCnetmesh.dart';

    main() {
      var awesome = new Awesome();
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme

'.source.dart':
  'Test clause':
    'prefix': 'test'
    'body': """
    test("${1:Test name}",(){
      $2
    }${3:, testOn: "browser,vm"});
    """
  'Async Test clause':
    'prefix': 'atest'
    'body': """
    test("${1:Test name}",() async {
      $2
      ${3:someStream}.listen(expectAsync(($4) {
        $5
        expect($4, $6);
      }));
    }${7:, testOn: "browser,vm"});
    """
  'Expect':
    'prefix': 'ex'
    'body': 'expect($1, $2);$3'
  'Expect Equals':
    'prefix': 'exeq'
    'body': 'expect($1, equals($2));$3'
  'Async testing schedule()':
    'prefix': 'sch'
    'body': 'schedule(() => $1);$2'
