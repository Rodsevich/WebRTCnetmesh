@TestOn('browser')
library test.generated_runner;

import './unit/mensajes_test.dart' as unit_mensajes_test;
import './unit/identidad_test.dart' as unit_identidad_test;
import './integration/cliente_test.dart' as integration_cliente_test;
import './integration/servidor_test.dart' as integration_servidor_test;
import 'package:test/test.dart';

void main() {
  unit_mensajes_test.main();
  unit_identidad_test.main();
  integration_cliente_test.main();
  integration_servidor_test.main();
}
