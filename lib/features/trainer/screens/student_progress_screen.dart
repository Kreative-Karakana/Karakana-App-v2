import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1A08),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Maendeleo ya Wanafunzi',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outlined,
              size: 64,
              color: Color(0xFFE8D5C8),
            ),
            const SizedBox(height: 16),
            Text(
              'Maendeleo ya Wanafunzi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A0A00),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kipengele hiki kitapatikana hivi karibuni.',
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
