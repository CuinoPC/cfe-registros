class TerminalDanada {
  final int id;
  final int terminalId;
  final String marca;
  final String modelo;
  final String serie;
  String? fechaReporte;
  String? fechaGuia;
  String? fechaDiagnostico;
  String? fechaAutorizacion;
  String? fechaReparacion;
  String diasReparacion;
  String costo;

  TerminalDanada({
    required this.id,
    required this.terminalId,
    required this.marca,
    required this.modelo,
    required this.serie,
    this.fechaReporte,
    this.fechaGuia,
    this.fechaDiagnostico,
    this.fechaAutorizacion,
    this.fechaReparacion,
    this.diasReparacion = "",
    this.costo = "",
  });

  // Convertir JSON a objeto
  factory TerminalDanada.fromJson(Map<String, dynamic> json) {
    return TerminalDanada(
      id: json['id'],
      terminalId: json['terminal_id'],
      marca: json['marca'],
      modelo: json['modelo'],
      serie: json['serie'],
      fechaReporte: json['fecha_reporte'],
      fechaGuia: json['fecha_guia'],
      fechaDiagnostico: json['fecha_diagnostico'],
      fechaAutorizacion: json['fecha_autorizacion'],
      fechaReparacion: json['fecha_reparacion'],
      diasReparacion: json['dias_reparacion'] ?? "",
      costo: json['costo'] ?? "",
    );
  }

  // Convertir objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "terminal_id": terminalId,
      "marca": marca,
      "modelo": modelo,
      "serie": serie,
      "fecha_reporte": fechaReporte,
      "fecha_guia": fechaGuia,
      "fecha_diagnostico": fechaDiagnostico,
      "fecha_autorizacion": fechaAutorizacion,
      "fecha_reparacion": fechaReparacion,
      "dias_reparacion": diasReparacion,
      "costo": costo,
    };
  }
}
