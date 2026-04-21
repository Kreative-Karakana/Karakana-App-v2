import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  static const _color = Color(0xFF1A2E5A);
  static const _colorLight = Color(0xFFE8EEF8);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const features = [
      [
        Icons.receipt_long_outlined,
        'Rekodi za Mauzo',
        'Hifadhi kila muamala wa mauzo kwa haraka na urahisi',
      ],
      [
        Icons.inventory_2_outlined,
        'Usimamizi wa Bidhaa',
        'Fuatilia stock na bei za bidhaa zako zote',
      ],
      [
        Icons.bar_chart_outlined,
        'Ripoti za Kila Siku',
        'Angalia mauzo, faida, na hasara kila siku',
      ],
      [
        Icons.people_outline,
        'Usimamizi wa Wateja',
        'Hifadhi taarifa za wateja wako wa kawaida',
      ],
      [
        Icons.print_outlined,
        'Chapisha Risiti',
        'Tuma au chapisha risiti kwa wateja moja kwa moja',
      ],
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: _color,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Mfumo wa Mauzo (POS)',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero header ──────────────────────────────────────────────
            Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0D1B3E),
                    Color(0xFF1A2E5A),
                    Color(0xFF2A4A8A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.point_of_sale_outlined,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mfumo wa Mauzo',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Simamia biashara yako kwa urahisi',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'INAKAMILISHWA',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Description ───────────────────────────────────────
                  Text(
                    'POS ni Nini?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0A00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mfumo wa Mauzo (Point of Sale) ni zana ya kisasa inayokuwezesha kusimamia biashara yako yote kutoka simu moja. Rekodi mauzo, simamia bidhaa, na pata ripoti kamili — kila wakati, kila mahali.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF5C3D2E),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Features ──────────────────────────────────────────
                  Text(
                    'Utakachopata',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0A00),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...features.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A1A2E5A),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _colorLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item[0] as IconData,
                              color: _color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item[1] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A0A00),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item[2] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF9E8070),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Interest form ─────────────────────────────────────
                  if (!_isSubmitted) ...[
                    Text(
                      'Kuwa wa Kwanza Kujua!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0A00),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Jisajili kupata arifa wakati POS inapopatikana.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF9E8070),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Jina Lako',
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: _color,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8D5C8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _color,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Weka jina lako' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Nambari ya Simu',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: _color,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE8D5C8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _color,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Weka nambari ya simu' : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _color,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => _isSubmitting = true);
                                        await Future.delayed(
                                          const Duration(milliseconds: 800),
                                        );
                                        if (!mounted) return;
                                        setState(() {
                                          _isSubmitting = false;
                                          _isSubmitted = true;
                                        });
                                      }
                                    },
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Niarifu Ninapozinduliwa',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: _color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Umesajiliwa!',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Asante! Tutakuarifiwa mara POS inapopatikana.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF5C3D2E),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
