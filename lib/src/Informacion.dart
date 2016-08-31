enum InformacionAPI {
  INDEFINIDO,
  NUEVO_USUARIO,
  CAMBIO_USUARIO,
  SALIDA_USUARIO,
  NUEVA_TRANSMISION,
  FIN_TRANSMISION
}

class Informacion {
  InformacionAPI tipo;

  Informacion() {
    tipo = InformacionAPI.INDEFINIDO;
  }

  factory Informacion.desdeTipo(InformacionAPI tipo) {
    switch (tipo) {
      case InformacionAPI.NUEVO_USUARIO:
      case InformacionAPI.CAMBIO_USUARIO:
      case InformacionAPI.SALIDA_USUARIO:
        return new InfoUsuarios(tipo);
        break;
      case InformacionAPI.NUEVA_TRANSMISION:
      case InformacionAPI.FIN_TRANSMISION:
        return new InfoTransmision(tipo);
      case InformacionAPI.INDEFINIDO:
        throw new Exception("Indefinido, no se qué hacer");
    }
  }
}

class InfoUsuarios extends Informacion {
  InfoUsuarios(InformacionAPI tipo) {
    this.tipo = tipo;
  }
}

class InfoTransmision extends Informacion {
  InfoTransmision(InformacionAPI tipo) {
    this.tipo = tipo;
  }
}
