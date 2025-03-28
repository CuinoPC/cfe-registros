class LectorDanado {
  final int id;
  final int lectorId;
  final String marca;
  final String modelo;
  final String area;
  final String folio;
  final String tipoConector;
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

  LectorDanado({
    required this.id,
    required this.lectorId,
    required this.marca,
    required this.modelo,
    required this.area,
    required this.folio,
    required this.tipoConector,
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
    required this.ticket,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "lector_id": lectorId,
      "marca": marca,
      "modelo": modelo,
      "area": area,
      "folio": folio,
      "tipo_conector": tipoConector,
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

  factory LectorDanado.fromJson(Map<String, dynamic> json) {
    return LectorDanado(
      id: json['id'],
      lectorId: json['lector_id'],
      marca: json['marca'],
      modelo: json['modelo'],
      area: json['area'] ?? 'No disponible',
      folio: json['folio'],
      tipoConector: json['tipo_conector'],
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
