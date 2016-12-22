///Class that the client would use in order to have everybody informed

part of WebRTCnetmesh.client;

class Identity {
  Identidad _id;

  bool _modificable;

  Identity(String name) {
    this._id = new Identidad(name);
    _modificable = true;
  }

  @visibleForTesting
  Identity.desdeEncubierto(this._id) {
    _modificable = false; //De un Pair o algo asi q no admite modificaciones
  }

  String get name => _id.nombre;

  void set name(String name) {
    if (_modificable) {
      CambioIdentidad cambio = new CambioIdentidad('n', _id.nombre, name);
      _id.nombre = name;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get email => _id.email;

  void set email(String email) {
    if (_modificable) {
      CambioIdentidad cambio = new CambioIdentidad('E', _id.email, email);
      _id.email = email;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get facebook_id => _id.id_feis;

  void set facebook_id(String facebook_id) {
    if (_modificable) {
      CambioIdentidad cambio =
          new CambioIdentidad('F', _id.id_feis, facebook_id);
      _id.id_feis = facebook_id;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get google_id => _id.id_goog;

  void set google_id(String google_id) {
    if (_modificable) {
      CambioIdentidad cambio = new CambioIdentidad('G', _id.id_goog, google_id);
      _id.id_goog = google_id;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }

  String get github_id => _id.id_github;

  void set github_id(String github_id) {
    if (_modificable) {
      CambioIdentidad cambio =
          new CambioIdentidad('g', _id.id_github, github_id);
      _id.id_github = github_id;
      _id.cambiosController.add(cambio);
    } else
      throw "Not possible to change Identities other than yours own";
  }
}
