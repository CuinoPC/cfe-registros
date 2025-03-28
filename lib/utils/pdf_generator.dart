import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generarPDFReporte({
  required String area,
  required List<Map<String, dynamic>> supervisiones,
  required List<Map<String, dynamic>> supervisionesLectores,
  required List<Map<String, dynamic>> supervisionesHoneywell,
  required String supervisorTIC,
  required String jefeCentro,
}) async {
  final regularFont = pw.Font.times();
  final boldFont = pw.Font.timesBold();
  final fallbackFonts = [regularFont]; // necesario para ✓ y acentos

  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      fontFallback: fallbackFonts,
    ),
  );
  final fecha = DateFormat('dd/MM/yyyy').format(DateTime.now());

  final imageLogo = pw.MemoryImage(
    (await rootBundle.load('assets/cfePDF.png')).buffer.asUint8List(),
  );

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(16),
      build: (context) => [
        // Encabezado con logo y título
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(imageLogo, width: 80),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Guía de Supervisión',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Terminales Portátiles y Lectores Ópticos',
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("División de Distribución Oriente",
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text("Tecnologías de la Información y Comunicaciones",
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 20),

        // Tabla con área y fecha en cuadros separados
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(5),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Centro de Trabajo por supervisar:',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(area,
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(5),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Lugar y Fecha',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('$area, $fecha',
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 18),

        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.teal900,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "TERMINALES NEWLAND",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // 🟩 TABLA DE SUPERVISIÓN
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(240), // INFORMACIÓN (4 columnas)
            1: const pw.FixedColumnWidth(
                270), // CONFIGURACIONES / EVIDENCIA (6 columnas)
            2: const pw.FixedColumnWidth(120), // SIGESTEL (2 columnas)
            3: const pw.FixedColumnWidth(120), // SISTIC (2 columnas)
            4: const pw.FixedColumnWidth(90), // SIITIC (2 columnas)
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("INFORMACIÓN",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ),
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("CONFIGURACIONES / EVIDENCIA",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ),
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("SIGESTEL",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ),
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("SISTIC",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ),
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text("SIITIC",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),

        pw.SizedBox(height: 1),

        // 🟡 Encabezado real y filas
        pw.Table.fromTextArray(
          headers: [
            'Inventario',
            'Serie',
            'Año de antigüedad',
            'RPE Usuario MySAP',
            'Fotografías físicas (6)',
            'Etiqueta normada de Activo Fijo sobre Tableta (legible)',
            'Chip con serie Tableta',
            'Foto de carcasa (0 = sin carcasa o en mal estado)',
            'APN',
            'Correo GMAIL',
            'Seguridad de desbloqueo',
            'Coincide Serie, SIM e IMEI',
            'Responsiva APN',
            'Centro de trabajo correcto',
            'Responsiva',
            'Serie correcta en SISTIC',
            'Serie correcta SIITIC',
            'Asignación de RPE correcto vs MySAP',
            'TOTAL',
          ],
          data: supervisiones.map((entry) {
            String check(value) => value == 1 ? 'Sí' : '';
            return [
              entry['inventario'] ?? '',
              entry['serie'] ?? '',
              entry['anio_antiguedad'] ?? '',
              entry['rpe_usuario'] ?? '',
              entry['fotografias_fisicas']?.toString() ?? '',
              check(entry['etiqueta_activo_fijo']),
              check(entry['chip_con_serie_tableta']),
              check(entry['foto_carcasa']),
              check(entry['apn']),
              check(entry['correo_gmail']),
              check(entry['seguridad_desbloqueo']),
              check(entry['coincide_serie_sim_imei']),
              check(entry['responsiva_apn']),
              check(entry['centro_trabajo_correcto']),
              check(entry['responsiva']),
              check(entry['serie_correcta_sistic']),
              check(entry['serie_correcta_siitic']),
              check(entry['asignacion_rpe_mysap']),
              entry['total']?.toString() ?? '0',
            ];
          }).toList(),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle:
              pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.center,
          headerAlignment: pw.Alignment.center,
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FixedColumnWidth(60),
            2: const pw.FixedColumnWidth(55),
            3: const pw.FixedColumnWidth(65),
            4: const pw.FixedColumnWidth(45),
            5: const pw.FixedColumnWidth(80),
            6: const pw.FixedColumnWidth(45),
            7: const pw.FixedColumnWidth(80),
            8: const pw.FixedColumnWidth(30),
            9: const pw.FixedColumnWidth(45),
            10: const pw.FixedColumnWidth(45),
            11: const pw.FixedColumnWidth(45),
            12: const pw.FixedColumnWidth(45),
            13: const pw.FixedColumnWidth(45),
            14: const pw.FixedColumnWidth(45),
            15: const pw.FixedColumnWidth(45),
            16: const pw.FixedColumnWidth(45),
            17: const pw.FixedColumnWidth(55),
            18: const pw.FixedColumnWidth(40),
          },
        ),
        // 🟦 TABLA HONEYWELL
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.blue900,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "TERMINALES HONEYWELL",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.Table.fromTextArray(
          headers: [
            'Inventario',
            'Serie',
            'RPE Usuario',
            'Coincide serie física/interna',
            'Fotografías físicas',
            'Asignación usuario SISTIC',
            'Registro serie SISTIC',
            'Centro trabajo SISTIC',
            'Asignación usuario SIITIC',
            'Registro serie SIITIC',
            'Centro trabajo SIITIC',
            'TOTAL',
          ],
          data: supervisionesHoneywell.map((entry) {
            String check(value) => value == 1 ? 'Sí' : '';
            return [
              entry['inventario'] ?? '',
              entry['serie'] ?? '',
              entry['rpe_usuario'] ?? '',
              check(entry['coincide_serie_fisica_vs_interna']),
              entry['fotografias_fisicas']?.toString() ?? '',
              check(entry['asignacion_usuario_sistic']),
              check(entry['registro_serie_sistic']),
              check(entry['centro_trabajo_sistic']),
              check(entry['asignacion_usuario_siitic']),
              check(entry['registro_serie_siitic']),
              check(entry['centro_trabajo_siitic']),
              entry['total']?.toString() ?? '0',
            ];
          }).toList(),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle:
              pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.center,
          headerAlignment: pw.Alignment.center,
          columnWidths: {
            0: const pw.FixedColumnWidth(60),
            1: const pw.FixedColumnWidth(60),
            2: const pw.FixedColumnWidth(70),
            3: const pw.FixedColumnWidth(70),
            4: const pw.FixedColumnWidth(45),
            5: const pw.FixedColumnWidth(55),
            6: const pw.FixedColumnWidth(55),
            7: const pw.FixedColumnWidth(55),
            8: const pw.FixedColumnWidth(55),
            9: const pw.FixedColumnWidth(55),
            10: const pw.FixedColumnWidth(55),
            11: const pw.FixedColumnWidth(40),
          },
        ),

        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  color: PdfColors.green900,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "LECTORES ÓPTICOS",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        // 🟡 Encabezado real y filas de Lectores
        pw.Table.fromTextArray(
          headers: [
            'Fecha',
            'Folio',
            'Marca',
            'Modelo',
            'Tipo Conector',
            'Fotografía Conector',
            'Fotografía Cincho/Folio',
            'Fotografía Cabezal',
            'Registro CTRL',
            'Ubicación CTRL',
            'Registro SIITIC',
            'Ubicación SIITIC',
            'TOTAL',
          ],
          data: supervisionesLectores.map((entry) {
            String check(value) => value == 1 ? 'Sí' : '';
            return [
              entry['fecha']?.toString().split('T').first ?? '',
              entry['folio'] ?? '',
              entry['marca'] ?? '',
              entry['modelo'] ?? '',
              entry['tipo_conector'] ?? '',
              check(entry['fotografia_conector']),
              check(entry['fotografia_cincho_folio']),
              check(entry['fotografia_cabezal']),
              check(entry['registro_ctrl_lectores']),
              check(entry['ubicacion_ctrl_lectores']),
              check(entry['registro_siitic']),
              check(entry['ubicacion_siitic']),
              entry['total']?.toString() ?? '0',
            ];
          }).toList(),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle:
              pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.center,
          headerAlignment: pw.Alignment.center,
          columnWidths: {
            0: const pw.FixedColumnWidth(55),
            1: const pw.FixedColumnWidth(55),
            2: const pw.FixedColumnWidth(60),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FixedColumnWidth(70),
            5: const pw.FixedColumnWidth(55),
            6: const pw.FixedColumnWidth(60),
            7: const pw.FixedColumnWidth(55),
            8: const pw.FixedColumnWidth(55),
            9: const pw.FixedColumnWidth(60),
            10: const pw.FixedColumnWidth(55),
            11: const pw.FixedColumnWidth(60),
            12: const pw.FixedColumnWidth(45),
          },
        ),

        // 🟩 FIRMAS
        pw.SizedBox(height: 50),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Supervisor TIC
            pw.Container(
              width: 250,
              height: 100,
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Supervisó TIC",
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 40), // espacio para firmar
                  pw.Text(
                    supervisorTIC,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Espacio entre firmas
            pw.SizedBox(width: 20),

            // Jefe del centro
            pw.Container(
              width: 250,
              height: 100,
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Por parte del centro de trabajo",
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 40), // espacio para firmar
                  pw.Text(
                    jefeCentro,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'supervision_$area.pdf',
  );
}
