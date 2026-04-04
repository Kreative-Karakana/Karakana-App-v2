import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1A08),
        foregroundColor: Colors.white,
        title: Text(
          'Msaada',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Support - Coming Soon',
          style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF5C3D2E)),
        ),
      ),
    );
  }
}
