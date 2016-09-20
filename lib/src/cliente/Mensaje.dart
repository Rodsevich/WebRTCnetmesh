import 'dart:html' show RtcIceCandidate, RtcSessionDescription;
import "../Mensaje.dart";

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeOfertaWebRTC extends Mensaje {
  RtcSessionDescription oferta;

  MensajeOfertaWebRTC(emisor, receptor, this.oferta) : super(emisor, receptor) {
    this.tipo = MensajesAPI.OFERTA_WEBRTC;
  }
  MensajeOfertaWebRTC.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.OFERTA_WEBRTC;
    List<String> datosOferta = msjEspecifico[0];
    this.oferta = new RtcSessionDescription();
    oferta.sdp = datosOferta[0];
  }

  @override
  _serializacionPropia() => [oferta.sdp];
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeRespuestaWebRTC extends Mensaje {
  RtcSessionDescription respuesta;

  MensajeRespuestaWebRTC(emisor, receptor, this.respuesta)
      : super(emisor, receptor) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
  }
  MensajeRespuestaWebRTC.desdeDecodificacion(
      List info_direccionamiento, List msjEspecifico)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
    this.respuesta = new RtcSessionDescription();
    respuesta.sdp = msjEspecifico[0];
  }

  @override
  _serializacionPropia() => [respuesta.sdp];
}

/// Mensaje que porta la negociacion SDP para establecer conexiones WebRTC
/// WebAPP --> Cliente --> Servidor
/// Servidor --> Cliente --> WebApp
class MensajeCandidatoICEWebRTC extends Mensaje {
  RtcIceCandidate candidato;

  MensajeCandidatoICEWebRTC(emisor, receptor, this.candidato)
      : super(emisor, receptor) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
  }
  MensajeCandidatoICEWebRTC.desdeDecodificacion(
      List info_direccionamiento, List datosCandidato)
      : super.desdeDecodificacion(info_direccionamiento) {
    this.tipo = MensajesAPI.RESPUESTA_WEBRTC;
    this.candidato = new RtcIceCandidate({
      "candidate": datosCandidato[0],
      "sdpMid": datosCandidato[1],
      "sdpMLineIndex": datosCandidato[2]
    });
  }

  @override
  _serializacionPropia() =>
      [candidato.candidate, candidato.sdpMid, candidato.sdpMLineIndex];
}
