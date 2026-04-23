import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';

class CourseBuilderScreen extends StatefulWidget {
  const CourseBuilderScreen({super.key});

  @override
  State<CourseBuilderScreen> createState() => _CourseBuilderScreenState();
}

class _CourseBuilderScreenState extends State<CourseBuilderScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1 — Details
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  String _selectedLevel = 'beginner';
  String _selectedCategory = '';
  List<Map<String, dynamic>> _categories = [];

  // Step 2 — Sections are added post-publish from the dashboard

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await ApiClient().dio.get('/api/v1/categories/');
      final data = res.data;
      final rawList = data is Map
          ? (data['results'] as List? ?? const [])
          : (data as List? ?? const []);
      if (!mounted) return;
      setState(() {
        _categories = rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first['id'].toString();
        }
      });
    } catch (_) {}
  }

  bool get _step1Valid =>
      _titleController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty;

  Future<void> _publishCourse() async {
    if (!_step1Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jaza jina na maelezo ya kozi.',
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFB00020),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final price = double.tryParse(_priceController.text.trim()) ?? 0;
      final body = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': price,
        'level': _selectedLevel,
        if (_selectedCategory.isNotEmpty) 'category': int.tryParse(_selectedCategory),
      };

      await ApiClient().dio.post('/api/v1/courses/', data: body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kozi imehifadhiwa! Itaonekana kwenye dashibodi yako.',
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFE87722),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiClient().parseError(e),
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFB00020),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Maelezo', 'Sehemu', 'Maswali', 'Chapisha'];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Unda Kozi Mpya',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Step indicator ─────────────────────────────────────────────
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
                                  ? const Color(0xFFE87722)
                                  : const Color(0xFFF5E6D8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: i < _currentStep
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : Text(
                                      '${i + 1}',
                                      style: GoogleFonts.montserrat(
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
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              color: i <= _currentStep
                                  ? const Color(0xFFE87722)
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
                                ? const Color(0xFFE87722)
                                : const Color(0xFFE8D5C8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Step content ───────────────────────────────────────────────
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

          // ── Navigation buttons ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE8D5C8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Nyuma',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_currentStep < 3) {
                              if (_currentStep == 0 && !_step1Valid) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Jaza jina na maelezo ya kozi.',
                                      style: GoogleFonts.montserrat(fontSize: 14),
                                    ),
                                    backgroundColor: const Color(0xFFB00020),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() => _currentStep++);
                            } else {
                              _publishCourse();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE87722),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
                            _currentStep < 3 ? 'Endelea' : 'Chapisha Kozi',
                            style: GoogleFonts.montserrat(
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

  // ── Step 1: Details ────────────────────────────────────────────────────────
  Widget _buildStep1() {
    const levels = [
      ('beginner', 'Mwanzo'),
      ('intermediate', 'Kati'),
      ('advanced', 'Juu'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Maelezo ya Kozi'),
          const SizedBox(height: 16),
          _field(
            controller: _titleController,
            label: 'Jina la Kozi *',
            hint: 'Mfano: Biashara Bila Mtaji',
          ),
          const SizedBox(height: 16),
          _field(
            controller: _descController,
            label: 'Maelezo ya Kozi *',
            hint: 'Elezea kozi yako kwa kina...',
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          // Category picker
          if (_categories.isNotEmpty) ...[
            Text(
              'Kategoria',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D1800),
              ),
            ),
            const SizedBox(height: 8),
            _dropdown<String>(
              value: _selectedCategory,
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['name'] as String? ?? '',
                            style: GoogleFonts.montserrat(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? ''),
            ),
            const SizedBox(height: 16),
          ],
          // Price + Level
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _priceController,
                  label: 'Bei (TZS)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kiwango',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _selectedLevel,
                      items: levels
                          .map((l) => DropdownMenuItem(
                                value: l.$1,
                                child: Text(l.$2,
                                    style: GoogleFonts.montserrat(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedLevel = v ?? 'beginner'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2: Sections ───────────────────────────────────────────────────────
  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Sehemu na Masomo'),
        const SizedBox(height: 8),
        Text(
          'Sehemu na masomo yanaweza kuongezwa baada ya kozi kuchapishwa kutoka kwenye dashibodi.',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF9E8070),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _infoCard(
          icon: Icons.info_outline,
          title: 'Jinsi ya Kuongeza Masomo',
          body:
              '1. Chapisha kozi kwanza\n2. Fungua kozi kutoka dashibodi\n3. Ongeza sehemu na video za masomo',
        ),
        const SizedBox(height: 16),
        _placeholderCard(
          icon: Icons.view_agenda_outlined,
          title: 'Sehemu za Kozi',
          subtitle: 'Panga masomo yako kwa sehemu',
        ),
        const SizedBox(height: 12),
        _placeholderCard(
          icon: Icons.play_lesson_outlined,
          title: 'Video na Maandishi',
          subtitle: 'Pakia video za masomo baada ya kuchapisha',
        ),
      ],
    );
  }

  // ── Step 3: Quiz ───────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Maswali ya Kozi'),
        const SizedBox(height: 8),
        Text(
          'Maswali yanaweza kuongezwa baada ya kozi kuchapishwa.',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF9E8070),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _infoCard(
          icon: Icons.quiz_outlined,
          title: 'Majaribio ya Kozi',
          body:
              'Baada ya kuchapisha kozi, unaweza kuunda maswali ya mtihani kutoka kwenye ukurasa wa majaribio.',
        ),
        const SizedBox(height: 16),
        _placeholderCard(
          icon: Icons.rule_folder_outlined,
          title: 'Vigezo vya Alama',
          subtitle: 'Chagua kiwango cha kufaulu (msingi: 70%)',
        ),
      ],
    );
  }

  // ── Step 4: Review & Publish ───────────────────────────────────────────────
  Widget _buildStep4() {
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final levelLabels = {
      'beginner': 'Mwanzo',
      'intermediate': 'Kati',
      'advanced': 'Juu',
    };
    final categoryName = _categories
        .firstWhere(
          (c) => c['id'].toString() == _selectedCategory,
          orElse: () => {'name': '—'},
        )['name'] as String? ??
        '—';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('Pitia na Chapisha'),
        const SizedBox(height: 16),
        _summaryTile('Jina la Kozi',
            _titleController.text.trim().isEmpty ? '—' : _titleController.text.trim()),
        _summaryTile('Kategoria', categoryName),
        _summaryTile(
          'Bei',
          price == 0 ? 'Bure' : 'TZS ${price.toStringAsFixed(0)}',
        ),
        _summaryTile('Kiwango', levelLabels[_selectedLevel] ?? _selectedLevel),
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
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFE87722),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Baada ya Kuchapisha',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D1800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Kozi itahifadhiwa kama rasimu. Unaweza kuongeza sehemu, masomo, na maswali kutoka dashibodi kabla ya kuiruhusu wanafunzi kuisajili.',
                style: GoogleFonts.montserrat(
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D5C8)),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF3D1800)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3D1800),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
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
          borderSide:
              const BorderSide(color: Color(0xFFE87722), width: 1.5),
        ),
      ),
    );
  }

  Widget _placeholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
            child: Icon(icon, color: const Color(0xFFE87722), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
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

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE87722).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE87722), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFF5C3D2E),
                    height: 1.6,
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
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: const Color(0xFF9E8070),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D1800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
