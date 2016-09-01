import "dart:html";
import "dart:async";
import "../Mensaje.dart";
import "../Identidad.dart";

Map _configuracion = {
  "iceServers": const [
    const {'url': 'stun:stun.l.google.com:19302'},
    const {'url': 'stun:stun1.l.google.com:19302'},
    const {'url': 'stun:stun2.l.google.com:19302'},
    const {'url': 'stun:stun3.l.google.com:19302'},
    const {'url': 'stun:stun4.l.google.com:19302'}
  ]
};

Map _restriccionDeMedios = {
  "optional": [
    {"RtpDataChannels": true},
    {"DtlsSrtpKeyAgreement": true}
  ]
};

/// Objeto que el cliente tendrá por cada conexión con otro [Par], que lo proveerá
/// de funcionalidad de alto nivel para facilitar la comunicación
class Par {
  final Identidad identidad_local;
  Identidad identidad_remota;
  DateTime _establecimientoConexion;
  RtcPeerConnection _conexion;
  RtcDataChannel _canal;

  Stream<Event> onConexion;
  Stream<Mensaje> onMensaje;

  StreamController<Event> _onConexionController;
  StreamController<Mensaje> _onMensajeController;

  bool get conectadoDirectamente => _canal.negotiated;

  Duration get tiempoConectado =>
      new DateTime.now().difference(_establecimientoConexion);

  DateTime get momentoEstablecimientoCanal => _establecimientoConexion;

  Par(Identidad identidad_local, Identidad this.identidad_remota)
      : this.identidad_local = identidad_local {
    _canal.onOpen.listen((e) {
      _establecimientoConexion = new DateTime.now();
      _onConexionController.add(e);
    });
  }

  void conectar([bool reliable = false]) {
    _conexion = new RtcPeerConnection(_configuracion, _restriccionDeMedios);
    _canal = _conexion.createDataChannel(
        "${identidad_local.id_sesion}-${identidad_remota.id_sesion}",
        {"reliable": reliable});
    _conexion.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true}
    }).then((RtcSessionDescription sessionDescription) {
      _conexion.setLocalDescription(sessionDescription);
      Mensaje oferta = new MensajeOfertaWebRTC(
          identidad_local.id, identidad_remota.id, sessionDescription);
      _onMensajeController.add(oferta);
    });
  }

  DateTime _varAuxiliarMedicionPing;

  Future<int> obtenerMicrosegundosDePing() async {}

  void enviarMensaje(Mensaje msj) {
    _canal.send(msj.toString());
  }
}
