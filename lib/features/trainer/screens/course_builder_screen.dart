import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseBuilderScreen extends StatefulWidget {
  const CourseBuilderScreen({super.key});

  @override
  State<CourseBuilderScreen> createState() => _CourseBuilderScreenState();
}

class _CourseBuilderScreenState extends State<CourseBuilderScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    const labels = ['Maelezo', 'Sehemu', 'Maswali', 'Chapisha'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1A08),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Unda Kozi Mpya',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: i <= _currentStep
                                  ? const Color(0xFFC4620A)
                                  : const Color(0xFFF5E6D8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: i < _currentStep
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: i <= _currentStep
                                            ? Colors.white
                                            : const Color(0xFF9E8070),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: i <= _currentStep
                                  ? const Color(0xFFC4620A)
                                  : const Color(0xFF9E8070),
                            ),
                          ),
                        ],
                      ),
                      if (i < 3)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            color: i < _currentStep
                                ? const Color(0xFFC4620A)
                                : const Color(0xFFE8D5C8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE8D5C8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Nyuma',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        _publishCourse();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4620A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _currentStep < 3 ? 'Endelea' : 'Chapisha Kozi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Maelezo ya Kozi'),
          const SizedBox(height: 16),
          _inputField('Jina la Kozi', 'Mfano: Biashara Bila Mtaji'),
          const SizedBox(height: 16),
          _inputField(
            'Maelezo ya Kozi',
            'Elezea kozi yako kwa kina...',
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          _inputField('Kategoria', 'Chagua kategoria'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _inputField('Bei', 'TZS 0')),
              const SizedBox(width: 12),
              Expanded(child: _inputField('Kiwango', 'Beginner')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Sehemu na Masomo'),
        const SizedBox(height: 16),
        _placeholderCard(
          title: 'Sehemu ya 1',
          subtitle: 'Ongeza kichwa cha sehemu na masomo yake',
          icon: Icons.view_agenda_outlined,
        ),
        const SizedBox(height: 12),
        _placeholderCard(
          title: 'Masomo',
          subtitle: 'Video, maandishi, na nyenzo za kujifunza',
          icon: Icons.play_lesson_outlined,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: Color(0xFFC4620A)),
          label: Text(
            'Ongeza Sehemu',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC4620A),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE8D5C8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Maswali ya Kozi'),
        const SizedBox(height: 16),
        _placeholderCard(
          title: 'Maswali ya Mwisho wa Somo',
          subtitle: 'Unda maswali ya kupima uelewa wa wanafunzi',
          icon: Icons.quiz_outlined,
        ),
        const SizedBox(height: 12),
        _placeholderCard(
          title: 'Vigezo vya Alama',
          subtitle: 'Chagua kiwango cha kufaulu na maoni ya matokeo',
          icon: Icons.rule_folder_outlined,
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Pitia na Chapisha'),
        const SizedBox(height: 16),
        _summaryTile('Jina la Kozi', 'Biashara Bila Mtaji'),
        _summaryTile('Kategoria', 'Ujasiriamali'),
        _summaryTile('Bei', 'TZS 0'),
        _summaryTile('Kiwango', 'Beginner'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8D5C8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kozi iko tayari kuchapishwa',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B1A08),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ukibonyeza chapisha, kozi itaonekana kwenye dashibodi yako kama rasimu ya majaribio.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF9E8070),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF3B1A08),
      ),
    );
  }

  Widget _inputField(String label, String hint, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC4620A), width: 1.5),
        ),
      ),
    );
  }

  Widget _placeholderCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FC4620A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6D8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFC4620A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B1A08),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D5C8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9E8070),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B1A08),
            ),
          ),
        ],
      ),
    );
  }

  void _publishCourse() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kozi yako imehifadhiwa kama rasimu!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
    context.pop();
  }
}
