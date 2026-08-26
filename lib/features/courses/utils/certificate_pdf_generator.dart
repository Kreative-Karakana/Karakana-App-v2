import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';

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

    final logoData = await rootBundle.load(
      'assets/images/Kreative_Karakana_-_Official_Logo_Icon.png',
    );
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final orange = PdfColor.fromHex('#E87722');
    final darkBrown = PdfColor.fromHex('#3D1800');
    const lightGrey = PdfColors.grey600;
    const cream = PdfColors.white;

    final dateStr = AppDateFormat.longDisplay.format(issuedAt.toLocal());
    final shortCertNum =
        certificateNumber.toUpperCase().replaceAll('-', '').substring(0, 10);
    final excerpt = courseExcerpt.length > 190
        ? '${courseExcerpt.substring(0, 190)}...'
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
                // Outer border
                pw.Positioned.fill(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(18),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: darkBrown, width: 2.4),
                    ),
                  ),
                ),
                // Inner accent border
                pw.Positioned.fill(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(27),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: orange, width: 0.8),
                    ),
                  ),
                ),
                // Premium header strip
                pw.Positioned(
                  top: 28,
                  left: 28,
                  right: 28,
                  child: pw.Container(
                    height: 26,
                    color: darkBrown,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'CHETI RASMI CHA UKAMILISHAJI',
                      style: pw.TextStyle(
                        font: montserratBold,
                        fontSize: 10,
                        color: cream,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                ),
                // Content
                pw.Positioned.fill(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.fromLTRB(56, 66, 56, 40),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Header
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
                                      'Jukwaa la Elimu, Ujuzi na Biashara',
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
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: orange, width: 1),
                                borderRadius: pw.BorderRadius.circular(6),
                              ),
                              child: pw.Text(
                                'TOLEO LA KIDIGITALI',
                                style: pw.TextStyle(
                                  font: montserratBold,
                                  fontSize: 8,
                                  color: orange,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        pw.Divider(color: orange, thickness: 1.2),

                        pw.Column(
                          children: [
                            pw.Text(
                              'Cheti hiki kinathibitisha kuwa',
                              style: pw.TextStyle(
                                font: montserratRegular,
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
                              pw.SizedBox(height: 10),
                              pw.Text(
                                'Kupitia tathmini na ufuatiliaji wa maendeleo, mshiriki ameonesha uelewa wa kina, nidhamu ya kujifunza, na uwezo wa kutumia maarifa ya kozi hii katika mazingira halisi ya kazi, biashara na maendeleo binafsi.\n\nMuhtasari wa kozi: $excerpt',
                                style: pw.TextStyle(
                                  font: montserratRegular,
                                  fontSize: 9.5,
                                  color: lightGrey,
                                  lineSpacing: 2,
                                ),
                                textAlign: pw.TextAlign.center,
                                maxLines: 4,
                              ),
                            ],
                          ],
                        ),

                        pw.Divider(color: orange, thickness: 1.2),

                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
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
                            pw.Container(
                              width: 72,
                              height: 72,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                border:
                                    pw.Border.all(color: darkBrown, width: 1.4),
                              ),
                              child: pw.Center(
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      'IME',
                                      style: pw.TextStyle(
                                        font: montserratBold,
                                        fontSize: 8,
                                        color: darkBrown,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    pw.Text(
                                      'THIBITISHWA',
                                      style: pw.TextStyle(
                                        font: montserratBold,
                                        fontSize: 7,
                                        color: orange,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    pw.Text(
                                      'KARAKANA',
                                      style: pw.TextStyle(
                                        font: montserratRegular,
                                        fontSize: 6.5,
                                        color: lightGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
}
