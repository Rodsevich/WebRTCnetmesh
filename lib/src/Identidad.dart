class Identidad {
  int id_sesion;
  String _nombre;
  String id_feis;
  String id_goog;
  String id_github;
  String email;

  String get nombre => _nombre;

  void set nombre(String nom) {
    for (int codigo in nom.codeUnits) {
      if (codigo < 'A'.codeUnits[0] ||
          codigo > 'z'.codeUnitAt(0) ||
          (codigo > 'Z'.codeUnitAt(0) && codigo < 'a'.codeUnitAt(0)))
        throw new Exception(
            "Name contains something else than just letters: '${new String.fromCharCode(codigo)}'");
    }
  }

  Identidad(int this.id_sesion);
  Identidad.desdeString(String codificacion) {
    List<String> vals = codificacion.split(',');
    nombre = vals[0];
    id_sesion = int.parse(vals[1]);
    for (int i = 2; i < vals.length; i++)
      switch (vals[i][0]) {
      case 'g':
        id_github = vals[i].substring(1);
        break;
      case 'F':
        id_feis = vals[i].substring(1);
        break;
      case 'G':
        id_goog = vals[i].substring(1);
        break;
      case 'E':
        email = vals[i].substring(1);
        break;
    }
  }

  String get id => id_sesion.toString();

  String toString() {
    String tmp = "$nombre,${id_sesion.toString()}";
    if (id_github != null) tmp += ",g$id_github";
    if (id_goog != null) tmp += ",G$id_goog";
    if (id_feis != null) tmp += ",F$id_feis";
    if (email != null) tmp += ",E$email";

    return tmp;
  }
}
