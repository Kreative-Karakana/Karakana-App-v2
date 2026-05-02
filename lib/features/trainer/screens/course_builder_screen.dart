import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../widgets/common/top_popup.dart';

class CourseBuilderScreen extends StatefulWidget {
  final int? courseId;

  const CourseBuilderScreen({super.key, this.courseId});

  @override
  State<CourseBuilderScreen> createState() => _CourseBuilderScreenState();
}

class _CourseBuilderScreenState extends State<CourseBuilderScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isLoadingCourse = false;

  // Step 1 — Details
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  String _selectedLevel = 'beginner';
  String _selectedCategory = '';
  List<Map<String, dynamic>> _categories = [];
  File? _coverImage;

  // Step 3 — Quiz (local state, submitted after course is created)
  final List<Map<String, dynamic>> _questions = [];
  final _passingScoreController = TextEditingController(text: '70');

  bool get _isEditMode => widget.courseId != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditMode) _loadExistingCourse();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _passingScoreController.dispose();
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
        if (_categories.isNotEmpty && _selectedCategory.isEmpty) {
          _selectedCategory = _categories.first['id'].toString();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadExistingCourse() async {
    setState(() => _isLoadingCourse = true);
    try {
      final res =
          await ApiClient().dio.get('/api/v1/courses/${widget.courseId}/');
      final data = res.data as Map? ?? {};
      if (!mounted) return;
      final catId = data['category']?['id'] ?? data['category'];
      setState(() {
        _titleController.text = data['title'] as String? ?? '';
        _descController.text = data['description'] as String? ?? '';
        _priceController.text = (data['price'] ?? '0').toString();
        _selectedLevel = data['level'] as String? ?? 'beginner';
        if (catId != null) _selectedCategory = catId.toString();
        _isLoadingCourse = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCourse = false);
    }
  }

  bool get _step1Valid =>
      _titleController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty;

  Future<void> _pickCoverImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() => _coverImage = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _saveQuiz(int courseId) async {
    if (_questions.isEmpty) return;
    try {
      final passingScore =
          int.tryParse(_passingScoreController.text.trim()) ?? 70;
      await ApiClient().dio.post(
        '/api/v1/courses/$courseId/quiz/',
        data: {
          'passing_score': passingScore,
          'questions': _questions
              .map((q) => {
                    'question': q['question'],
                    'options': q['options'],
                    'correct_answer': q['correct'],
                  })
              .toList(),
        },
      );
    } catch (_) {}
  }

  Future<void> _submitCourse() async {
    if (!_step1Valid) {
      _showError('Jaza jina na maelezo ya kozi.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final price = double.tryParse(_priceController.text.trim()) ?? 0;

      if (_coverImage != null) {
        // Multipart upload when a cover image is selected
        final formData = FormData.fromMap({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'price': price.toString(),
          'level': _selectedLevel,
          if (_selectedCategory.isNotEmpty)
            'category': int.tryParse(_selectedCategory),
          'cover_photo': await MultipartFile.fromFile(_coverImage!.path,
              filename: 'cover.jpg'),
        });

        if (_isEditMode) {
          await ApiClient()
              .dio
              .patch('/api/v1/courses/${widget.courseId}/', data: formData);
          if (!mounted) return;
          _showSuccess('Mabadiliko yamehifadhiwa!');
          context.pop();
        } else {
          final res = await ApiClient()
              .dio
              .post('/api/v1/courses/', data: formData);
          final createdId = (res.data as Map?)?['id'] as int?;
          if (createdId != null) await _saveQuiz(createdId);
          if (!mounted) return;
          _showSuccess('Kozi imehifadhiwa! Ongeza sehemu na masomo sasa.');
          if (createdId != null) {
            context.pushReplacement('/trainer/course/$createdId/sections',
                extra: {'title': _titleController.text.trim()});
          } else {
            context.pop();
          }
        }
      } else {
        final body = {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'price': price,
          'level': _selectedLevel,
          if (_selectedCategory.isNotEmpty)
            'category': int.tryParse(_selectedCategory),
        };

        if (_isEditMode) {
          await ApiClient()
              .dio
              .patch('/api/v1/courses/${widget.courseId}/', data: body);
          if (!mounted) return;
          _showSuccess('Mabadiliko yamehifadhiwa!');
          context.pop();
        } else {
          final res =
              await ApiClient().dio.post('/api/v1/courses/', data: body);
          final createdId = (res.data as Map?)?['id'] as int?;
          if (createdId != null) await _saveQuiz(createdId);
          if (!mounted) return;
          _showSuccess('Kozi imehifadhiwa! Ongeza sehemu na masomo sasa.');
          if (createdId != null) {
            context.pushReplacement('/trainer/course/$createdId/sections',
                extra: {'title': _titleController.text.trim()});
          } else {
            context.pop();
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(ApiClient().parseError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) => showTopPopup(context, msg);

  void _showSuccess(String msg) => showTopPopup(context, msg, isError: false);

  void _addQuestion() {
    final questionController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    int selectedCorrect = 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8D5C8),
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text('Ongeza Swali',
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D1800))),
                const SizedBox(height: 16),
                TextField(
                  controller: questionController,
                  maxLines: 3,
                  decoration: _inputDecoration('Andika swali hapa...'),
                ),
                const SizedBox(height: 16),
                Text('Majibu (chagua sahihi)',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800))),
                const SizedBox(height: 8),
                ...List.generate(4, (i) {
                  final labels = ['A', 'B', 'C', 'D'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => setSheet(() => selectedCorrect = i),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedCorrect == i
                                ? const Color(0xFFE87722)
                                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8)),
                          ),
                          child: Center(
                            child: Text(labels[i],
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selectedCorrect == i
                                        ? Colors.white
                                        : const Color(0xFF9E8070))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: optionControllers[i],
                          decoration: _inputDecoration('Jibu ${labels[i]}'),
                        ),
                      ),
                    ]),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE87722),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                        elevation: 0),
                    onPressed: () {
                      final q = questionController.text.trim();
                      final opts =
                          optionControllers.map((c) => c.text.trim()).toList();
                      if (q.isEmpty || opts.any((o) => o.isEmpty)) {
                        showTopPopup(context, 'Jaza swali na majibu yote manne.');
                        return;
                      }
                      setState(() => _questions.add({
                            'question': q,
                            'options': opts,
                            'correct': selectedCorrect,
                          }));
                      Navigator.of(ctx).pop();
                    },
                    child: Text('Hifadhi Swali',
                        style: GoogleFonts.montserrat(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
            fontSize: 14, color: const Color(0xFFBDA99C)),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFE87722), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final labels = ['Maelezo', 'Sehemu', 'Maswali', 'Chapisha'];

    if (_isLoadingCourse) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF3D1800),
          elevation: 0,
          leading: const BackButton(color: Colors.white),
          title: Text('Hariri Kozi',
              style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE87722))),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          _isEditMode ? 'Hariri Kozi' : 'Unda Kozi Mpya',
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
            color: Theme.of(context).cardColor,
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
            color: Theme.of(context).cardColor,
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
                                _showError('Jaza jina na maelezo ya kozi.');
                                return;
                              }
                              setState(() => _currentStep++);
                            } else {
                              _submitCourse();
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
                            _currentStep < 3
                                ? 'Endelea'
                                : (_isEditMode
                                    ? 'Hifadhi Mabadiliko'
                                    : 'Chapisha Kozi'),
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

  // ── Step 1: Details + Thumbnail ────────────────────────────────────────────
  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

          // ── Cover image picker ──
          GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _coverImage != null
                      ? const Color(0xFFE87722)
                      : const Color(0xFFE8D5C8),
                  width: _coverImage != null ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _coverImage != null
                  ? Stack(fit: StackFit.expand, children: [
                      Image.file(_coverImage!, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _coverImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Color(0xFF3D1800),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ])
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            color: Color(0xFFE87722), size: 36),
                        const SizedBox(height: 8),
                        Text('Pakia Picha ya Kozi',
                            style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7B3A10))),
                        const SizedBox(height: 4),
                        Text('JPG au PNG (hiari)',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: const Color(0xFFBDA99C))),
                      ],
                    ),
            ),
          ),

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
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              items: _categories
                  .where((c) => c['id'] != null)
                  .map((c) => DropdownMenuItem<String>(
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
                      value: _selectedLevel.isEmpty ? null : _selectedLevel,
                      items: levels
                          .map((l) => DropdownMenuItem<String>(
                                value: l.$1,
                                child: Text(l.$2,
                                    style:
                                        GoogleFonts.montserrat(fontSize: 14)),
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

  // ── Step 2: Sections info ──────────────────────────────────────────────────
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

  // ── Step 3: Inline quiz builder ────────────────────────────────────────────
  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Maswali ya Kozi'),
          const SizedBox(height: 8),
          Text(
            'Ongeza maswali ya mtihani (hiari). Maswali yatahifadhiwa mara baada ya kozi kuchapishwa.',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: const Color(0xFF9E8070), height: 1.5),
          ),
          const SizedBox(height: 20),

          // Passing score
          Text('Kiwango cha Kufaulu (%)',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D1800))),
          const SizedBox(height: 8),
          _field(
            controller: _passingScoreController,
            label: 'Asilimia ya Kufaulu',
            hint: '70',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maswali (${_questions.length})',
                  style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D1800))),
              TextButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_circle_outline,
                    size: 18, color: Color(0xFFE87722)),
                label: Text('Ongeza Swali',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE87722))),
              ),
            ],
          ),

          if (_questions.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFE87722).withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                const Icon(Icons.quiz_outlined,
                    color: Color(0xFFE87722), size: 36),
                const SizedBox(height: 8),
                Text('Hakuna maswali bado',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7B3A10))),
                const SizedBox(height: 4),
                Text('Bonyeza "Ongeza Swali" kuanza',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: const Color(0xFF9E8070))),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ..._questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final opts = q['options'] as List;
              final correct = q['correct'] as int;
              final labels = ['A', 'B', 'C', 'D'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                              color: Color(0xFFE87722),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('${i + 1}',
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(q['question'] as String,
                              style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3D1800))),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _questions.removeAt(i)),
                          child: const Icon(Icons.delete_outline,
                              color: Color(0xFF9E8070), size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...opts.asMap().entries.map((opt) {
                      final isCorrect = opt.key == correct;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrect
                                  ? const Color(0xFFE87722)
                                  : (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8)),
                            ),
                            child: Center(
                              child: Text(labels[opt.key],
                                  style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isCorrect
                                          ? Colors.white
                                          : const Color(0xFF9E8070))),
                            ),
                          ),
                          Expanded(
                            child: Text(opt.value as String,
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: const Color(0xFF5C3D2E))),
                          ),
                          if (isCorrect)
                            const Icon(Icons.check_circle,
                                size: 14, color: Color(0xFFE87722)),
                        ]),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Step 4: Review & Publish ───────────────────────────────────────────────
  Widget _buildStep4() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        _sectionTitle(_isEditMode ? 'Pitia Mabadiliko' : 'Pitia na Chapisha'),
        const SizedBox(height: 16),
        if (_coverImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(_coverImage!,
                height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],
        _summaryTile('Jina la Kozi',
            _titleController.text.trim().isEmpty ? '—' : _titleController.text.trim()),
        _summaryTile('Kategoria', categoryName),
        _summaryTile(
            'Bei', price == 0 ? 'Bure' : 'TZS ${price.toStringAsFixed(0)}'),
        _summaryTile('Kiwango', levelLabels[_selectedLevel] ?? _selectedLevel),
        if (!_isEditMode)
          _summaryTile('Maswali ya Mtihani',
              _questions.isEmpty ? 'Hakuna' : '${_questions.length} maswali'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFE87722), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode ? 'Kuhusu Uhariri' : 'Baada ya Kuchapisha',
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
                _isEditMode
                    ? 'Mabadiliko yatahifadhiwa mara moja. Wanafunzi wataona mabadiliko baada ya kurasa kusasishwa.'
                    : 'Kozi itahifadhiwa kama rasimu. Unaweza kuongeza sehemu, masomo, na maswali kutoka dashibodi kabla ya kuiruhusu wanafunzi kuisajili.',
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
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dedupedItems = <DropdownMenuItem<T>>[];
    final seenValues = <T?>{};
    for (final item in items) {
      if (seenValues.add(item.value)) {
        dedupedItems.add(item);
      }
    }
    final safeValue =
        dedupedItems.any((item) => item.value == value) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
      ),
      child: DropdownButton<T>(
        value: safeValue,
        hint: Text('Chagua...',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: const Color(0xFF9E8070))),
        isExpanded: true,
        underline: const SizedBox(),
        items: dedupedItems,
        onChanged: onChanged,
        style: GoogleFonts.montserrat(
            fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF3D1800)),
        dropdownColor: Theme.of(context).cardColor,
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
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.5),
        ),
      ),
    );
  }

  Widget _placeholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0FC4620A), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFE87722), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: const Color(0xFF9E8070))),
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
                Text(title,
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800))),
                const SizedBox(height: 4),
                Text(body,
                    style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF5C3D2E),
                        height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: const Color(0xFF9E8070))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00))),
          ),
        ],
      ),
    );
  }
}
