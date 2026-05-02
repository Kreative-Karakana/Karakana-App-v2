import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificatePdfGenerator {
  static Future<pw.Document> generate({
    required String studentName,
    required String courseTitle,
    required String courseExcerpt,
    required DateTime issuedAt,
    required String certificateNumber,
  }) async {
    final doc = pw.Document();
    final montserratRegular = await PdfGoogleFonts.montserratRegular();
    final montserratBold = await PdfGoogleFonts.montserratBold();
    final montserratItalic = await PdfGoogleFonts.montserratItalic();

    final logoData = await rootBundle.load(
      'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
    );
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final orange = PdfColor.fromHex('#E87722');
    final darkBrown = PdfColor.fromHex('#3D1800');
    const lightGrey = PdfColors.grey600;
    const cream = PdfColors.white;

    final dateStr = DateFormat('d MMMM yyyy').format(issuedAt.toLocal());
    final shortCertNum = certificateNumber
        .toUpperCase()
        .replaceAll('-', '')
        .substring(0, 10);
    final excerpt = courseExcerpt.length > 220
        ? '${courseExcerpt.substring(0, 220)}...'
        : courseExcerpt;

    // A4 landscape
    final pageFormat = PdfPageFormat(
      PdfPageFormat.a4.height,
      PdfPageFormat.a4.width,
      marginAll: 0,
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context ctx) {
          return pw.Container(
            color: cream,
            child: pw.Stack(
              children: [
                // Outer orange border
                pw.Positioned.fill(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: orange, width: 3),
                    ),
                  ),
                ),
                // Inner thin border
                pw.Positioned.fill(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(27),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: orange, width: 0.8),
                    ),
                  ),
                ),
                // Corner accents
                _cornerSquare(pw.Alignment.topLeft, orange),
                _cornerSquare(pw.Alignment.topRight, orange),
                _cornerSquare(pw.Alignment.bottomLeft, orange),
                _cornerSquare(pw.Alignment.bottomRight, orange),
                // Content
                pw.Positioned.fill(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(56, 40, 56, 40),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // ── Header ───────────────────────────────────────
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Row(
                              children: [
                                pw.Image(logoImage, width: 52, height: 52),
                                pw.SizedBox(width: 12),
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'KREATIVE KARAKANA',
                                      style: pw.TextStyle(
                                        font: montserratBold,
                                        fontSize: 15,
                                        color: darkBrown,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                    pw.Text(
                                      'Jukwaa la Elimu ya Ujasiriamali Tanzania',
                                      style: pw.TextStyle(
                                        font: montserratRegular,
                                        fontSize: 9,
                                        color: orange,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            pw.Text(
                              'CHETI CHA UKAMILISHAJI',
                              style: pw.TextStyle(
                                font: montserratBold,
                                fontSize: 9,
                                color: orange,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),

                        // ── Divider ──────────────────────────────────────
                        pw.Divider(color: orange, thickness: 1.2),

                        // ── Main body ─────────────────────────────────────
                        pw.Column(
                          children: [
                            pw.Text(
                              'Hii ni kuthibitisha kwamba',
                              style: pw.TextStyle(
                                font: montserratItalic,
                                fontSize: 12,
                                color: lightGrey,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              studentName,
                              style: pw.TextStyle(
                                font: montserratBold,
                                fontSize: 38,
                                color: darkBrown,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'amekamilisha kwa mafanikio kozi ya',
                              style: pw.TextStyle(
                                font: montserratRegular,
                                fontSize: 12,
                                color: lightGrey,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              courseTitle,
                              style: pw.TextStyle(
                                font: montserratBold,
                                fontSize: 22,
                                color: orange,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            if (excerpt.isNotEmpty) ...[
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'Kwa cheti hiki, Karakana inatambua kujituma, uelewa wa kina, na matumizi ya maarifa haya katika mazingira halisi ya kazi na biashara.\n\n$excerpt',
                                style: pw.TextStyle(
                                  font: montserratRegular,
                                  fontSize: 9,
                                  color: lightGrey,
                                ),
                                textAlign: pw.TextAlign.center,
                                maxLines: 3,
                              ),
                            ],
                          ],
                        ),

                        // ── Divider ──────────────────────────────────────
                        pw.Divider(color: orange, thickness: 1.2),

                        // ── Footer ────────────────────────────────────────
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            // Date block
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  dateStr,
                                  style: pw.TextStyle(
                                    font: montserratBold,
                                    fontSize: 13,
                                    color: darkBrown,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Tarehe ya Ukamilishaji',
                                  style: pw.TextStyle(
                                    font: montserratRegular,
                                    fontSize: 9,
                                    color: lightGrey,
                                  ),
                                ),
                              ],
                            ),
                            // Certificate number block
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  shortCertNum,
                                  style: pw.TextStyle(
                                    font: montserratBold,
                                    fontSize: 12,
                                    color: darkBrown,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Namba ya Cheti',
                                  style: pw.TextStyle(
                                    font: montserratRegular,
                                    fontSize: 9,
                                    color: lightGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _cornerSquare(pw.Alignment alignment, PdfColor color) {
    const size = 10.0;
    const margin = 16.5;

    double? top, bottom, left, right;
    if (alignment == pw.Alignment.topLeft) {
      top = margin;
      left = margin;
    } else if (alignment == pw.Alignment.topRight) {
      top = margin;
      right = margin;
    } else if (alignment == pw.Alignment.bottomLeft) {
      bottom = margin;
      left = margin;
    } else {
      bottom = margin;
      right = margin;
    }

    return pw.Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: pw.Container(
        width: size,
        height: size,
        color: color,
      ),
    );
  }
}
