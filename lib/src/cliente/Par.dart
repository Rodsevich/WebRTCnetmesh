part of WebRTCNetmesh.client;

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
class Par {
  final Identidad identidad_local;
  Identidad identidad_remota;

  Stream<Event> onConexion;
  Stream<Mensaje> onMensaje;

  DateTime _establecimientoConexion;
  DateTime _ultimaComunicacion;
  List<Stopwatch> _muestrasLatencia = new List(60);
  int _punteroMuestrasLatencia = 0;
  Timer _medidorLapsoPing;

  RtcPeerConnection _conexion;
  RtcDataChannel _canal;

  StreamController<Event> _onConexionController;
  StreamController<Mensaje> _onMensajeController;

  Duration _lapsoMedicionPing = new Duration(seconds: 1);

  bool get conectadoDirectamente => _canal.negotiated;

  Duration get tiempoSinComunicacion =>
      new DateTime.now().difference(_ultimaComunicacion);
  Duration get tiempoConectado =>
      new DateTime.now().difference(_establecimientoConexion);

  DateTime get momentoEstablecimientoCanal => _establecimientoConexion;

  Par(Identidad identidad_local, Identidad this.identidad_remota)
      : this.identidad_local = identidad_local {
    _onConexionController = new StreamController();
    _onMensajeController = new StreamController();
    this.onConexion = _onConexionController.stream;
    this.onMensaje = _onMensajeController.stream;
    _conexion = new RtcPeerConnection(_configuracion, _restriccionDeMedios);
    _conexion.onIceCandidate.listen((RtcIceCandidateEvent event) {
      if (event.candidate != null)
        _onMensajeController.add(new MensajeCandidatoICEWebRTC(
            identidad_local, identidad_remota, event.candidate));
    });
    _canal = _conexion.createDataChannel(
        "${identidad_local.id_sesion}-${identidad_remota.id_sesion}",
        {"reliable": true});
    _canal.onOpen.listen((e) {
      _establecimientoConexion = new DateTime.now();
      _medidorLapsoPing =
          new Timer.periodic(_lapsoMedicionPing, _calcularLatencia);
      _onConexionController.add(e);
    });
    _canal.onMessage.listen((me) => _manejadorMensajes(me.data));
    _canal.onClose.listen((e) => _medidorLapsoPing.cancel());
  }

  Future<MensajeOfertaWebRTC> mensaje_inicio_conexion() async {
    RtcSessionDescription sessionDescription = await _conexion.createOffer({
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true}
    });
    _conexion.setLocalDescription(sessionDescription);
    return new MensajeOfertaWebRTC(
        identidad_local.id_sesion, identidad_remota.id, sessionDescription);
  }

  Future<MensajeRespuestaWebRTC> mensaje_respuesta_inicio_conexion(
      RtcSessionDescription oferta) async {
    _conexion.setRemoteDescription(oferta);
    RtcSessionDescription sessionDescription = await _conexion.createAnswer();
    return new MensajeRespuestaWebRTC(
        identidad_local.id_sesion, identidad_remota.id, sessionDescription);
  }

  void setear_respuesta(RtcSessionDescription respuesta) {
    _conexion.setRemoteDescription(respuesta);
  }

  void setear_ice_candidate_remoto(RtcIceCandidate candidato) {
    _conexion.addIceCandidate(candidato, null, null);
  }

  void _manejadorMensajes(Mensaje mensaje) {
    //Evitar loops
    if (mensaje.ids_intermediarios.contains(identidad_local.id_sesion)) return;
    if (mensaje.id_receptor == this.identidad_local.id_sesion) {
      switch (mensaje.tipo) {
        case MensajesAPI.PING:
          enviarMensaje(new MensajePong.desdeMensajePing(mensaje));
          return;
          break;
        case MensajesAPI.PONG:
          MensajePong mensaje = mensaje as MensajePong;
          _muestrasLatencia[mensaje.indice].stop();
          return;
          break;
        default:
          //Delegar manejo del mensaje al controlador general que contiene a este Par
          _onMensajeController.add(mensaje);
          _ultimaComunicacion = new DateTime.now();
      }
    } else {
      //Agregar este par como repetidor del envío del mensaje
      mensaje.ids_intermediarios.add(identidad_local.id_sesion);
      _onMensajeController.add(mensaje);
      _ultimaComunicacion = new DateTime.now();
    }
  }

  void _calcularLatencia(Timer timer) {
    var index = _muestrasLatencia.length % _punteroMuestrasLatencia++;
    MensajePing msj =
        new MensajePing(identidad_local.id_sesion, identidad_remota.id, index);
    //Separar en una avriable indepte. para no medir como tiempo de ping la implícita conversion a String al mandarlo
    String str = msj.toCodificacion();
    _muestrasLatencia[index] = new Stopwatch()..start();
    _canal.sendString(str);
  }

  void enviarMensaje(Mensaje msj) {
    _canal.sendString(msj.toCodificacion());
  }
}
