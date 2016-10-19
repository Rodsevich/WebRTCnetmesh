import 'dart:async';
import 'dart:html';
import 'package:WebRTCnetmesh/src/WebRTCnetmesh_base.dart';
import 'package:WebRTCnetmesh/src/cliente/Mensaje.dart';
import 'package:WebRTCnetmesh/src/cliente/WebRTCnetmesh.dart';
import 'package:meta/meta.dart';

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

/// Objeto que el cliente tendrá por cada conexión con otro [Par], que lo
/// proveerá de funcionalidad de alto nivel para facilitar la comunicación
class Par extends Asociado with Exportable<Pair>{
  final Identidad _identidad_local;
  Identidad identidad;

  StreamController<Event> onConexionController = new StreamController();
  StreamController<Mensaje> onMensajeController = new StreamController();
  Stream<Event> get onConexion => onConexionController.stream;
  Stream<Mensaje> get onMensaje => onMensajeController.stream;

  @override
  RtcDataChannel canal;

  RtcPeerConnection conexion;

  Par(Identidad identidad_local, Identidad this.identidad)
      : this._identidad_local = identidad_local {
    conexion = new RtcPeerConnection(_configuracion, _restriccionDeMedios);
    conexion.onIceCandidate.listen((RtcIceCandidateEvent event) {
      if (event.candidate != null)
        onMensajeController.add(new MensajeCandidatoICEWebRTC(
            identidad_local, identidad, event.candidate));
    });
    canal = conexion.createDataChannel(
        "${identidad_local.id_sesion}-${identidad.id_sesion}",
        {"reliable": true});
    canal.onOpen.listen((e) {
      establecimientoConexion = new DateTime.now();
      medidorLapsoPing =
          new Timer.periodic(lapsoMedicionPing, calcularLatencia);
      onConexionController.add(e);
    });
    canal.onMessage.listen((me) => _manejadorDatosDesdeCanal(me.data));
    canal.onClose.listen((e) => medidorLapsoPing.cancel());
  }

  Future<MensajeOfertaWebRTC> mensaje_inicio_conexion() async {
    RtcSessionDescription sessionDescription = await conexion.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true}
    });
    conexion.setLocalDescription(sessionDescription);
    return new MensajeOfertaWebRTC(
        _identidad_local.id_sesion, identidad.id, sessionDescription);
  }

  Future<MensajeRespuestaWebRTC> mensaje_respuesta_inicio_conexion(
      RtcSessionDescription oferta) async {
    conexion.setRemoteDescription(oferta);
    RtcSessionDescription sessionDescription = await conexion.createAnswer();
    return new MensajeRespuestaWebRTC(
        _identidad_local.id_sesion, identidad.id, sessionDescription);
  }

  void setear_respuesta(RtcSessionDescription respuesta) {
    conexion.setRemoteDescription(respuesta);
  }

  void setear_ice_candidate_remoto(RtcIceCandidate candidato) {
    conexion.addIceCandidate(candidato, null, null);
  }

  void _manejadorDatosDesdeCanal(MessageEvent messageEvent) {
    log("Se recibió el texto: ${messageEvent.data}");
    Mensaje mensaje = new Mensaje.desdeCodificacion(messageEvent.data);
    //Evitar loops
    if (mensaje.ids_intermediarios.contains(_identidad_local.id_sesion)) return;
    if (mensaje.id_receptor == this._identidad_local.id_sesion) {
      switch (mensaje.tipo) {
        case MensajesAPI.PING:
          enviarMensaje(new MensajePong.desdeMensajePing(mensaje));
          return;
          break;
        case MensajesAPI.PONG:
          MensajePong mensaje = mensaje as MensajePong;
          muestrasLatencia[mensaje.indice].stop();
          return;
          break;
        default:
          //Delegar manejo del mensaje al controlador general que contiene a este Par
          onMensajeController.add(mensaje);
          ultimaComunicacion = new DateTime.now();
      }
    } else {
      //Agregar este par como repetidor del envío del mensaje
      mensaje.ids_intermediarios.add(_identidad_local.id_sesion);
      onMensajeController.add(mensaje);
      ultimaComunicacion = new DateTime.now();
    }
  }

  void calcularLatencia(Timer timer) {
    var index = muestrasLatencia.length % punteroMuestrasLatencia++;
    MensajePing msj =
        new MensajePing(_identidad_local.id_sesion, identidad.id, index);
    //Separar en una variable indepte. para no medir como tiempo de ping la implícita conversion a String al mandarlo
    String str = msj.toCodificacion();
    muestrasLatencia[index] = new Stopwatch()..start();
    canal.sendString(str);
  }

  void enviarMensaje(Mensaje msj) {
    canal.sendString(msj.toCodificacion());
  }
}

///Class that represents another client
class Pair extends Associate{
  Par _par;

  Identity get identity => _par.identidad.aExportable();

  Pair(){
    throw "Can't create; they should be taken from WebRTCNetmesh";
  }

  //Todo: Ver si se puede meterle un _ tanto aca como en el mixin Exportable<T>
  @visibleForTesting
  Pair.desdeEncubierto(this._par);

}
