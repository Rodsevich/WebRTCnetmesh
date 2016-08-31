enum ComandosAPI { INDEFINIDO, CAMBIAR_SLIDE, MOSTRAR_ALERT }

abstract class Comando {
  /// variable que tendrá la referencia al objetoq ue ejecutará el comando
  var ejecutor;
  Function funcion_ejecutora;
  ComandosAPI tipo;

  Comando() {
    tipo = ComandosAPI.INDEFINIDO;
  }

  factory Comando.desdeTipo(ComandosAPI tipo) {
    switch (tipo) {
      case ComandosAPI.CAMBIAR_SLIDE:
        return new CambiarSlide();
        break;
      case ComandosAPI.MOSTRAR_ALERT:
        return new MostrarAlert();
        break;
      default:
    }
  }

  int codificacionComandoAPI(ComandosAPI msj) {
    List<ComandosAPI> vals = ComandosAPI.values;
    for (var i in vals) if (msj == vals[i]) return i;
    return ComandosAPI.INDEFINIDO.index;
  }

  ComandosAPI decodificacionComandoAPI(int index) => ComandosAPI.values[index];

  ejecutar();
}

class CambiarSlide extends Comando {
  CambiarSlide(WebApp ejecutor) {
    this.ejecutor = ejecutor;
    this.funcion_ejecutora = ejecutarEnWebApp();
  }

  ejecutarEnWebApp() {}
}

class MostrarAlert extends Comando {
  MostrarAlert(WebApp ejecutor) {
    this.ejecutor = ejecutor;
    this.funcion_ejecutora = ejecutarEnWebApp();
  }

  ejecutarEnWebApp() {}
}

//class ComandoX extends Comando {
//  ComandoX(Servidor ejecutor) {
//    this.ejecutor = ejecutor;
//    this.funcion_ejecutora = ejecutarEnServidor();
//  }
//
//  ComandoX(WebApp ejecutor) {
//    this.ejecutor = ejecutor;
//    this.funcion_ejecutora = ejecutarEnWebApp();
//  }
//
//  ejecutarEnServidor(){}
//  ejecutarEnWebApp(){}
//}
