import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import '../../../core/network/api_client.dart';

class CourseMaterialViewerScreen extends StatefulWidget {
  final String downloadUrl;
  final String materialName;

  const CourseMaterialViewerScreen({
    super.key,
    required this.downloadUrl,
    required this.materialName,
  });

  @override
  State<CourseMaterialViewerScreen> createState() =>
      _CourseMaterialViewerScreenState();
}

class _CourseMaterialViewerScreenState
    extends State<CourseMaterialViewerScreen> {
  late final Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _downloadBytes();
  }

  Future<Uint8List> _downloadBytes() async {
    try {
      final response = await ApiClient().dio.get<List<int>>(
            widget.downloadUrl,
            options: Options(responseType: ResponseType.bytes),
          );
      return Uint8List.fromList(response.data!);
    } catch (e) {
      throw ApiClient().parseError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D1800),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        leading: const BackButton(color: Colors.white),
        title: Text(
          widget.materialName,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE87722)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
            );
          }
          return PdfPreview(
            build: (format) => snapshot.data!,
            allowSharing: true,
            allowPrinting: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            pdfFileName: widget.materialName,
          );
        },
      ),
    );
  }
}
