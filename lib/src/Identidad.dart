import 'dart:developer';

class Identidad {
  int id_sesion;
  String _nombre;
  String id_feis;
  String id_goog;
  String id_github;
  String email;
  bool es_servidor = false;

  String get nombre => _nombre;

  void set nombre(String nom) {
    for (int codigo in nom.codeUnits) {
      if (codigo < 'A'.codeUnits[0] && codigo != ' '.codeUnitAt(0) ||
          codigo > 'z'.codeUnitAt(0) ||
          (codigo > 'Z'.codeUnitAt(0) && codigo < 'a'.codeUnitAt(0)))
        throw new Exception(
            "Name contains something else than just letters: '${new String.fromCharCode(codigo)}'");
    }
    _nombre = nom;
  }

  Identidad(String this._nombre);
  Identidad.desdeCodificacion(codificacion) {
    if (!(codificacion is List || codificacion is String))
      throw new Exception("que hago con un ${codificacion.runtimeType}?");
    if (codificacion is List) codificacion = codificacion.join(',');
    if ((codificacion as String).startsWith("(")) {
      if ((codificacion as String).endsWith(")"))
        codificacion = codificacion.substring(1, codificacion.length - 1);
      else
        throw new Exception("Algo muy raro pasó O.o");
    }
    List<String> vals = codificacion.split(',');
    this.nombre = vals[0];
    if (vals.length >= 2) this.id_sesion = int.parse(vals[1]);
    for (int i = 2; i < vals.length; i++)
      switch (vals[i][0]) {
        case '\$':
          this.es_servidor = true;
          break;
        case 'g':
          this.id_github = vals[i].substring(1);
          break;
        case 'F':
          this.id_feis = vals[i].substring(1);
          break;
        case 'G':
          this.id_goog = vals[i].substring(1);
          break;
        case 'E':
          this.email = vals[i].substring(1);
          break;
      }
  }

  String get id => id_sesion.toString();

  List paraSerializar() {
    List tmp = ["$nombre"];
    if (id_sesion != null) tmp.add(id_sesion);
    if (id_github != null) tmp.add("g$id_github");
    if (id_goog != null) tmp.add("G$id_goog");
    if (id_feis != null) tmp.add("F$id_feis");
    if (email != null) tmp.add("E$email");
    if (es_servidor) tmp.add('\$');
    return tmp;
  }

  String toString() => "(${paraSerializar().join(',')})";
  String toJson() => toString();

  bool operator ==(Identidad otra) {
    if (this.id_sesion == null || otra.id_sesion == null)
      return this.nombre == otra.nombre;
    else
      return this.id_sesion == otra.id_sesion;
  }
}
