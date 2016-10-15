part of WebRTCNetmesh.client;

///Class that the client would use in order to have everybody informed
class Identity {
  Identidad _id;

  Identity(String name) {
    this._id = new Identidad(name);
  }

  String get name => _id.nombre;

  void set name(String name) {
    CambioIdentidad cambio;
    new CambioIdentidad('n', _id.nombre, name);
    _id.nombre = name;
    _id.cambiosController.add(cambio);
  }

  String get email => _id.email;

  void set email(String email) {
    CambioIdentidad cambio;
    new CambioIdentidad('E', _id.email, email);
    _id.email = email;
    _id.cambiosController.add(cambio);
  }

  String get facebook_id => _id.id_feis;

  void set facebook_id(String facebook_id) {
    CambioIdentidad cambio;
    new CambioIdentidad('F', _id.id_feis, facebook_id);
    _id.id_feis = facebook_id;
    _id.cambiosController.add(cambio);
  }

  String get google_id => _id.id_goog;

  void set google_id(String google_id) {
    CambioIdentidad cambio;
    new CambioIdentidad('G', _id.id_goog, google_id);
    _id.id_goog = google_id;
    _id.cambiosController.add(cambio);
  }

  String get github_id => _id.id_github;

  void set github_id(String github_id) {
    CambioIdentidad cambio;
    new CambioIdentidad('g', _id.id_github, github_id);
    _id.id_github = github_id;
    _id.cambiosController.add(cambio);
  }
}
