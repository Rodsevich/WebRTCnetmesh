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
  DateTime establecimientoConexion;
  RtcPeerConnection conexion;
  RtcDataChannel canal;

  Stream<Event> onConexion;
  Stream<Mensaje> onMensaje;

  StreamController<Event> _onConexionController;
  StreamController<Mensaje> _onMensajeController;

  bool get conectadoDirectamente => canal.negotiated;

  Par(Identidad identidad_local, Identidad this.identidad_remota)
      : this.identidad_local = identidad_local;

  conectar([bool reliable = false]) {
    conexion = new RtcPeerConnection(_configuracion, _restriccionDeMedios);
    canal = conexion.createDataChannel(
        "${identidad_local.id_sesion}-${identidad_remota.id_sesion}",
        {"reliable": reliable});
    conexion.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true}
    }).then((RtcSessionDescription sessionDescription) {
      conexion.setLocalDescription(sessionDescription);
      Mensaje oferta = new MensajeOfertaWebRTC(
          identidad_local.id, identidad_remota.id, sessionDescription);
      _onMensajeController.add(oferta);
    });
  }

  enviarMensaje(Mensaje msj);
}
