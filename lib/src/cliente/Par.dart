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

  Stream<Event> onConexion;
  Stream<MessageEvent> onMensaje;

  DateTime _establecimientoConexion;
  List _muestrasLatencia = new List(60);
  int _punteroMuestrasLatencia = 0;
  RtcPeerConnection _conexion;
  RtcDataChannel _canal;

  StreamController<Event> _onConexionController;
  StreamController<MessageEvent> _onMensajeController;

  bool get conectadoDirectamente => _canal.negotiated;

  Duration get tiempoConectado =>
      new DateTime.now().difference(_establecimientoConexion);

  DateTime get momentoEstablecimientoCanal => _establecimientoConexion;

  Par(Identidad identidad_local, Identidad this.identidad_remota)
      : this.identidad_local = identidad_local {
    _canal.onOpen.listen((e) {
      _establecimientoConexion = new DateTime.now();
      _calcularLatencia();
      _onConexionController.add(e);
    });
    _canal.onMessage.listen(_manejadorMensajes);
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
          identidad_local.id_sesion, identidad_remota.id, sessionDescription);
      _onMensajeController.add(oferta);
    });
  }

  void _manejadorMensajes(MessageEvent mensaje_llano) {
    Mensaje mensaje = new Mensaje.desdeCodificacion(mensaje_llano.data);
    //Evitar loops
    if (mensaje.ids_intermediarios.contains(identidad_local.id_sesion)) return;
    if (mensaje.id_receptor == this.identidad_local.id_sesion) {
      switch (mensaje.tipo) {
        case MensajesAPI.PING:
          _canal.send(new MensajePong.desdeMensajePing(mensaje));
          return;
          break;
        case MensajesAPI.PONG:
          Duration duracion =
              new DateTime.now().difference(_muestrasLatencia[mensaje.indice]);
          _muestrasLatencia[mensaje.indice] = duracion;
          return;
      }
    }
    //Delegar manejo del mensaje al controlado general que contiene a este Par
    _onMensajeController.add(mensaje_llano);
  }

  void _calcularLatencia() {
    var index = _muestrasLatencia.length % _punteroMuestrasLatencia++;
    MensajePing msj =
        new MensajePing(identidad_local.id_sesion, identidad_remota.id, index);
    String str = msj.toString();
    _muestrasLatencia[index] = new DateTime.now();
    _canal.send(str);
  }

  void enviarMensaje(Mensaje msj) {
    _canal.send(msj.toString());
  }
}
