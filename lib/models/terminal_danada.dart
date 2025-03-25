class TerminalDanada {
  final int id;
  final int terminalId;
  final String marca;
  final String modelo;
  final String area;
  final String serie;
  final String inventario;
  String? fechaReporte;
  String? fechaGuia;
  String? fechaDiagnostico;
  String? fechaAutorizacion;
  String? fechaReparacion;
  int diasReparacion;
  double costo;
  String piezasReparadas;
  String observaciones;
  String archivoPdf;
  String ticket;

  TerminalDanada(
      {required this.id,
      required this.terminalId,
      required this.marca,
      required this.modelo,
      required this.area,
      required this.serie,
      required this.inventario,
      this.fechaReporte,
      this.fechaGuia,
      this.fechaDiagnostico,
      this.fechaAutorizacion,
      this.fechaReparacion,
      this.diasReparacion = 0,
      this.costo = 0.0,
      required this.piezasReparadas,
      required this.observaciones,
      required this.archivoPdf,
      required this.ticket});

  /// 📌 Convertir un objeto TerminalDanada a un mapa para usar en la interfaz
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "terminal_id": terminalId,
      "marca": marca,
      "modelo": modelo,
      "area": area,
      "serie": serie,
      "inventario": inventario,
      "fechaReporte": fechaReporte,
      "fechaGuia": fechaGuia,
      "fechaDiagnostico": fechaDiagnostico,
      "fechaAutorizacion": fechaAutorizacion,
      "fechaReparacion": fechaReparacion,
      "diasReparacion": diasReparacion.toString(),
      "costo": costo.toString(),
      "piezasReparadas": piezasReparadas,
      "observaciones": observaciones,
      "archivoPdf": archivoPdf,
      "ticket": ticket,
    };
  }

  /// 📌 Convertir JSON a objeto TerminalDanada
  factory TerminalDanada.fromJson(Map<String, dynamic> json) {
    return TerminalDanada(
      id: json['id'],
      terminalId: json['terminal_id'],
      marca: json['marca'],
      modelo: json['modelo'],
      area: json['area'] ?? 'No disponible',
      serie: json['serie'],
      inventario: json['inventario'],
      fechaReporte: json['fecha_reporte'],
      fechaGuia: json['fecha_guia'],
      fechaDiagnostico: json['fecha_diagnostico'],
      fechaAutorizacion: json['fecha_autorizacion'],
      fechaReparacion: json['fecha_reparacion'],
      diasReparacion: json['dias_reparacion'] != null
          ? int.parse(json['dias_reparacion'].toString())
          : 0,
      costo:
          json['costo'] != null ? double.parse(json['costo'].toString()) : 0.0,
      piezasReparadas: json['piezas_reparadas'] ?? '',
      observaciones: json['observaciones'] ?? '',
      archivoPdf: json['archivo_pdf'] ?? '',
      ticket: json['ticket'] ?? '',
    );
  }
}
