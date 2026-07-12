import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../widgets/common/top_popup.dart';
import '../../courses/models/quiz_model.dart';
import '../../courses/services/quiz_service.dart';
import '../utils/course_contract.dart';

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
  String _selectedLevel = CourseContract.levelBeginner;
  String _selectedCategory = '';
  Map<String, String> _fieldErrors = {};
  List<Map<String, dynamic>> _categories = [];
  File? _coverImage;
  String? _existingStatus;
  String? _rejectionReason;

  // Step 3 — Quiz (local state, submitted after course is created)
  final List<Map<String, dynamic>> _questions = [];
  final _passingScoreController = TextEditingController(text: '70');
  final _cooldownController = TextEditingController(text: '15');
  bool _requiredForCertificate = false;

  bool get _isEditMode => widget.courseId != null;
  bool get _isRejected => CourseContract.isRejected(_existingStatus);

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
    _cooldownController.dispose();
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
        final mapped = rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final seen = <String>{};
        _categories = mapped.where((c) {
          final id = c['id']?.toString();
          if (id == null || id.isEmpty) return false;
          return seen.add(id);
        }).toList();
        if (_categories.isNotEmpty &&
            !_categories.any((c) => c['id'].toString() == _selectedCategory)) {
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
        _descController.text =
            _cleanRichTextDescription(data['description'] as String? ?? '');
        _priceController.text = (data['price'] ?? '0').toString();
        _selectedLevel =
            CourseContract.normalizeLevel(data['level'] as String?);
        if (catId != null) _selectedCategory = catId.toString();
        _existingStatus = data['status'] as String?;
        _rejectionReason = CourseContract.rejectionReason(data);
        _isLoadingCourse = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCourse = false);
    }
  }

  String _cleanRichTextDescription(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    try {
      final decoded = jsonDecode(value);
      List<dynamic>? ops;
      if (decoded is Map && decoded['ops'] is List) {
        ops = decoded['ops'] as List;
      } else if (decoded is List) {
        ops = decoded;
      }
      if (ops != null) {
        final text = StringBuffer();
        for (final op in ops) {
          if (op is Map && op['insert'] is String) {
            text.write(op['insert'] as String);
          }
        }
        return text
            .toString()
            .replaceAll('\r\n', '\n')
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join('\n\n');
      }
    } catch (_) {}
    return value;
  }

  bool get _step1Valid => CourseContract.validatePayloadInput(
        _payloadInput,
        requireCategory: _categories.isNotEmpty,
      ).isValid;

  CoursePayloadInput get _payloadInput => CoursePayloadInput(
        title: _titleController.text,
        description: _descController.text,
        priceText: _priceController.text,
        level: _selectedLevel,
        categoryId: _selectedCategory,
        status: CourseContract.submitForReviewStatus,
      );

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
      final payload = QuizDraftPayload(
        passingScore: int.tryParse(_passingScoreController.text.trim()) ?? 70,
        failedRetryCooldownMinutes:
            int.tryParse(_cooldownController.text.trim()) ?? 15,
        requiredForCertificate: _requiredForCertificate,
        questions: _questions
            .map((q) => QuizDraftQuestionInput(
                  question: q['question'] as String,
                  options: List<String>.from(q['options'] as List),
                  correctAnswer: q['correct'] as int,
                  explanation: q['explanation'] as String? ?? '',
                ))
            .toList(),
      );
      await QuizService().createQuizDraft(courseId, payload);
    } catch (e) {
      // Course creation already succeeded at this point — a quiz-save
      // failure shouldn't undo that, so this is a non-blocking warning
      // rather than an error that stops the flow. The trainer can finish
      // authoring the quiz from the quiz manager screen afterwards.
      if (mounted) {
        showTopPopup(
          context,
          'Kozi imehifadhiwa lakini mtihani haukuhifadhiwa: $e',
        );
      }
    }
  }

  Future<void> _submitCourse() async {
    final validation = CourseContract.validatePayloadInput(
      _payloadInput,
      requireCategory: _categories.isNotEmpty,
    );
    if (!validation.isValid) {
      setState(() => _fieldErrors = validation.fieldErrors);
      _showError(validation.firstError ?? 'Tafadhali kagua taarifa za kozi.');
      return;
    }

    final wasRejected = _isRejected;

    setState(() {
      _fieldErrors = {};
      _isSubmitting = true;
    });

    try {
      final payload = CourseContract.buildPayload(_payloadInput);
      final editSuccessMessage = wasRejected
          ? 'Kozi yako imewasilishwa tena kwa ukaguzi. Itachapishwa baada ya kupitishwa na timu ya Kreative Karakana.'
          : 'Kozi yako imetumwa kwa ukaguzi. Itachapishwa baada ya kupitishwa na timu ya Kreative Karakana.';

      if (_coverImage != null) {
        // Multipart upload when a cover image is selected
        final formData = FormData.fromMap({
          ...payload,
          'cover_photo': await MultipartFile.fromFile(_coverImage!.path,
              filename: 'cover.jpg'),
        });

        if (_isEditMode) {
          await ApiClient()
              .dio
              .patch('/api/v1/courses/${widget.courseId}/', data: formData);
          if (!mounted) return;
          _showSuccess(editSuccessMessage);
          context.pop();
        } else {
          final res =
              await ApiClient().dio.post('/api/v1/courses/', data: formData);
          final createdId = (res.data as Map?)?['id'] as int?;
          if (createdId != null) await _saveQuiz(createdId);
          if (!mounted) return;
          _showSuccess(
            'Kozi yako imetumwa kwa ukaguzi. Itachapishwa baada ya kupitishwa na timu ya Kreative Karakana.',
          );
          if (createdId != null) {
            context.pushReplacement('/trainer/course/$createdId/sections',
                extra: {'title': _titleController.text.trim()});
          } else {
            context.pop();
          }
        }
      } else {
        if (_isEditMode) {
          await ApiClient()
              .dio
              .patch('/api/v1/courses/${widget.courseId}/', data: payload);
          if (!mounted) return;
          _showSuccess(editSuccessMessage);
          context.pop();
        } else {
          final res =
              await ApiClient().dio.post('/api/v1/courses/', data: payload);
          final createdId = (res.data as Map?)?['id'] as int?;
          if (createdId != null) await _saveQuiz(createdId);
          if (!mounted) return;
          _showSuccess(
            'Kozi yako imetumwa kwa ukaguzi. Itachapishwa baada ya kupitishwa na timu ya Kreative Karakana.',
          );
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
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF2A1A0A)
                                    : const Color(0xFFF5E6D8)),
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
                        showTopPopup(
                            context, 'Jaza swali na majibu yote manne.');
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
          borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final labels = ['Maelezo', 'Sehemu', 'Maswali', 'Ukaguzi'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A0A00) : const Color(0xFFFFF8F4);
    final surfaceColor = Theme.of(context).cardColor;
    final title = _isEditMode ? 'Hariri Kozi' : 'Unda Kozi Mpya';
    final subtitle = _isEditMode
        ? (_isRejected
            ? 'Kozi hii ilikataliwa. Rekebisha kulingana na sababu iliyotolewa kisha uwasilishe tena.'
            : 'Safisha maudhui, panga sehemu, na tuma mabadiliko kwa ukaguzi.')
        : 'Jaza maelezo ya kozi, kisha tuma kwa ukaguzi wa timu ya Kreative Karakana.';

    if (_isLoadingCourse) {
      return Scaffold(
        backgroundColor: bgColor,
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
        body: const SafeArea(
            child: Center(child: KarakanaWaveLoader(color: Color(0xFFE87722)))),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(title,
            style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Ukaguzi',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE8D5C8),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0FC4620A),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE87722).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Color(0xFFE87722),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3D1800),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            color: const Color(0xFF7B3A10),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPill('Kozi', const Color(0xFFE87722)),
                            _buildPill('Sehemu', const Color(0xFF3D1800)),
                            _buildPill('Maswali', const Color(0xFF9E8070)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isRejected) _buildRejectionBanner(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
              ),
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 34,
                              height: 34,
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
                            const SizedBox(height: 6),
                            Text(
                              labels[i],
                              style: GoogleFonts.montserrat(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
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
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: i < _currentStep
                                    ? const Color(0xFFE87722)
                                    : const Color(0xFFE8D5C8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
              ),
            ),
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE8D5C8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(
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
                              child: KarakanaWaveLoader(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep < 3
                                  ? 'Endelea'
                                  : (_isEditMode
                                      ? (_isRejected
                                          ? 'Wasilisha Tena kwa Ukaguzi'
                                          : 'Tuma Mabadiliko')
                                      : 'Tuma kwa Ukaguzi'),
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
      ),
    );
  }

  // ── Step 1: Details + Thumbnail ────────────────────────────────────────────
  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 24;
    const levels = CourseContract.levelOptions;

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Maelezo ya Kozi'),
          const SizedBox(height: 14),
          _buildCoverPicker(isDark),
          const SizedBox(height: 16),
          _field(
            controller: _titleController,
            label: 'Jina la Kozi *',
            hint: 'Mfano: Biashara Bila Mtaji',
            errorText: _fieldErrors['title'],
          ),
          const SizedBox(height: 16),
          _field(
            controller: _descController,
            label: 'Maelezo ya Kozi *',
            hint: 'Elezea kozi yako kwa kina...',
            maxLines: 5,
            errorText: _fieldErrors['description'],
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
              errorText: _fieldErrors['category'],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  controller: _priceController,
                  label: 'Bei (TZS)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  errorText: _fieldErrors['price'],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdownField<String>(
                  label: 'Kiwango',
                  value: _selectedLevel.isEmpty ? null : _selectedLevel,
                  hint: 'Chagua...',
                  errorText: _fieldErrors['level'],
                  items: levels
                      .map((l) => DropdownMenuItem<String>(
                            value: l.value,
                            child: Text(l.label,
                                style: GoogleFonts.montserrat(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _selectedLevel = v ?? CourseContract.levelBeginner),
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
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 150;
    return ListView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      children: [
        _sectionTitle('Sehemu na Masomo'),
        const SizedBox(height: 8),
        Text(
          'Sehemu na masomo yanaweza kuongezwa kutoka kwenye dashibodi. Kila kilichoongezwa au kuhaririwa kitatumwa kwa ukaguzi kabla ya kuchapishwa.',
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
              '1. Tuma kozi kwa ukaguzi\n2. Fungua kozi kutoka dashibodi\n3. Ongeza sehemu na video za masomo kwa ukaguzi',
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
          subtitle: 'Pakia video za masomo kwa ukaguzi',
        ),
      ],
    );
  }

  // ── Step 3: Inline quiz builder ────────────────────────────────────────────
  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 150;
    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Maswali ya Kozi'),
          const SizedBox(height: 8),
          _infoCard(
            icon: Icons.quiz_outlined,
            title: 'Maswali ya Mtihani',
            body:
                'Ongeza maswali ya hiari sasa, kisha yahifadhiwe pamoja na kozi itakapotumwa kwa ukaguzi.',
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

          const SizedBox(height: 16),
          Text('Muda wa Kusubiri Baada ya Kushindwa (dakika)',
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D1800))),
          const SizedBox(height: 8),
          _field(
            controller: _cooldownController,
            label: 'Dakika za Kusubiri',
            hint: '15',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Hitajika kwa Cheti',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800))),
              ),
              Switch(
                value: _requiredForCertificate,
                activeThumbColor: const Color(0xFFE87722),
                onChanged: (v) => setState(() => _requiredForCertificate = v),
              ),
            ],
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
                  border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
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
                              color: Color(0xFFE87722), shape: BoxShape.circle),
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
                          onTap: () => setState(() => _questions.removeAt(i)),
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
                                  : (isDark
                                      ? const Color(0xFF2A1A0A)
                                      : const Color(0xFFF5E6D8)),
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
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 150;
    final categoryName = _categories.firstWhere(
          (c) => c['id'].toString() == _selectedCategory,
          orElse: () => {'name': '—'},
        )['name'] as String? ??
        '—';

    return ListView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      children: [
        _sectionTitle(_isEditMode ? 'Pitia Mabadiliko' : 'Pitia na Tuma'),
        const SizedBox(height: 16),
        if (_coverImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(_coverImage!,
                height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
        ],
        _summaryTile(
            'Jina la Kozi',
            _titleController.text.trim().isEmpty
                ? '—'
                : _titleController.text.trim()),
        _summaryTile('Kategoria', categoryName),
        _summaryTile(
            'Bei', price == 0 ? 'Bure' : 'TZS ${price.toStringAsFixed(0)}'),
        _summaryTile('Kiwango', CourseContract.levelLabel(_selectedLevel)),
        if (!_isEditMode)
          _summaryTile('Maswali ya Mtihani',
              _questions.isEmpty ? 'Hakuna' : '${_questions.length} maswali'),
        const SizedBox(height: 16),
        _infoCard(
          icon: Icons.verified_outlined,
          title: _isEditMode ? 'Kuhusu Uhariri' : 'Baada ya Kutuma',
          body: _isEditMode
              ? 'Mabadiliko yatatumwa kwa timu ya Kreative Karakana kwa ukaguzi. Wanafunzi wataona yaliyopitishwa baada ya kuidhinishwa.'
              : 'Kozi itatumwa kwa timu ya Kreative Karakana kwa ukaguzi. Baada ya kupitishwa ndipo itaweza kuonekana kwa wanafunzi.',
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _dropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? errorText,
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
    return InputDecorator(
      decoration: InputDecoration(
        errorText: errorText,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFFE87722), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                const Color(0xFF3D1800)),
        dropdownColor: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? errorText,
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

    return DropdownButtonHideUnderline(
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          floatingLabelStyle: GoogleFonts.montserrat(
            color: const Color(0xFFE87722),
            fontWeight: FontWeight.w600,
          ),
          labelStyle: GoogleFonts.montserrat(
            color: const Color(0xFF9E8070),
            fontSize: 13,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFE87722), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          underline: const SizedBox(),
          items: dedupedItems,
          onChanged: onChanged,
          hint: Text(
            hint,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFFBDA99C),
            ),
          ),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyLarge?.color ??
                const Color(0xFF3D1800),
          ),
          dropdownColor: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
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

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCoverPicker(bool isDark) {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF8F4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _coverImage != null
                ? const Color(0xFFE87722)
                : const Color(0xFFE8D5C8),
            width: _coverImage != null ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _coverImage != null
            ? Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(_coverImage!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _coverImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF3D1800).withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Gusa kubadilisha picha ya kozi',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE87722).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: Color(0xFFE87722), size: 30),
                    ),
                    const SizedBox(height: 14),
                    Text('Pakia Picha ya Kozi',
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7B3A10))),
                    const SizedBox(height: 6),
                    Text(
                      'JPG au PNG, hiari lakini inapendeza zaidi kwa wanafunzi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: const Color(0xFFBDA99C)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        floatingLabelStyle: GoogleFonts.montserrat(
          color: const Color(0xFFE87722),
          fontWeight: FontWeight.w600,
        ),
        labelStyle: GoogleFonts.montserrat(
          color: const Color(0xFF9E8070),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
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

  Widget _buildRejectionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFB71C1C).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFB71C1C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: Imekataliwa',
                    style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB71C1C))),
                const SizedBox(height: 4),
                Text(
                  _rejectionReason ??
                      'Timu ya Kreative Karakana haikutoa sababu maalum. Wasiliana nao kwa maelezo zaidi.',
                  style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      color: const Color(0xFF7B3A10),
                      height: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rekebisha maudhui hapa chini kisha uwasilishe tena kwa ukaguzi.',
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB71C1C)),
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
        border:
            Border.all(color: const Color(0xFFE87722).withValues(alpha: 0.3)),
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
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE8D5C8)),
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
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        const Color(0xFF1A0A00))),
          ),
        ],
      ),
    );
  }
}
