import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BizManagerScreen extends StatelessWidget {
  const BizManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5A1A),
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Msimamizi wa Biashara',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.business_center_outlined,
                size: 40,
                color: Color(0xFF2E5A1A),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Msimamizi wa Biashara',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A0A00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inakuja Hivi Karibuni',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9E8070),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
