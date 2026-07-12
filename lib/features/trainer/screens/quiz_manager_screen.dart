import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/common/top_popup.dart';
import '../../courses/models/quiz_model.dart';
import '../../courses/services/quiz_service.dart';
import '../../courses/utils/quiz_contract.dart';

class QuizManagerScreen extends StatefulWidget {
  final int courseId;

  const QuizManagerScreen({super.key, required this.courseId});

  @override
  State<QuizManagerScreen> createState() => _QuizManagerScreenState();
}

class _QuizManagerScreenState extends State<QuizManagerScreen> {
  final _quizService = QuizService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSubmittingReview = false;
  String? _loadError;
  QuizSummary? _summary;

  // Editable draft state — populated from the current draft version, or
  // left blank when creating a fresh one.
  bool _isEditing = false;
  final List<Map<String, dynamic>> _questions = [];
  final TextEditingController _passingScoreController =
      TextEditingController(text: '70');
  final TextEditingController _cooldownController =
      TextEditingController(text: '15');
  bool _requiredForCertificate = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passingScoreController.dispose();
    _cooldownController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final summary = await _quizService.getCourseQuiz(widget.courseId);
      setState(() {
        _summary = summary;
        _isLoading = false;
        if (summary.draftVersion != null) {
          _enterEditMode(summary.draftVersion);
        } else {
          _isEditing = false;
        }
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  void _enterEditMode(QuizVersionSummary? source) {
    _questions.clear();
    if (source != null) {
      _passingScoreController.text = source.passingScore.toString();
      _cooldownController.text = source.failedRetryCooldownMinutes.toString();
      _requiredForCertificate = source.requiredForCertificate;
      for (final q in source.questions) {
        final correctIndex = q.options.indexWhere((o) => o.isCorrect == true);
        _questions.add({
          'question': q.content,
          'options': q.options.map((o) => o.text).toList(),
          'correct': correctIndex < 0 ? 0 : correctIndex,
          'explanation': q.explanation ?? '',
        });
      }
    } else {
      _passingScoreController.text = '70';
      _cooldownController.text = '15';
      _requiredForCertificate = false;
    }
    _isEditing = true;
  }

  QuizDraftPayload _buildPayload() {
    return QuizDraftPayload(
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
  }

  Future<void> _saveDraft() async {
    final payload = _buildPayload();
    final validation = QuizContract.validateDraft(
      passingScore: payload.passingScore,
      questions: payload.questions,
    );
    if (!validation.isValid) {
      showTopPopup(context, validation.firstError!);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final hasDraft = _summary?.draftVersion != null;
      if (hasDraft) {
        await _quizService.updateQuizDraft(widget.courseId, payload);
      } else {
        await _quizService.createQuizDraft(widget.courseId, payload);
      }
      if (!mounted) return;
      showTopPopup(context, 'Rasimu imehifadhiwa!', isError: false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitForReview() async {
    if (_questions.isEmpty) {
      showTopPopup(context, 'Ongeza maswali angalau moja kwanza.');
      return;
    }
    setState(() => _isSubmittingReview = true);
    try {
      // Ensure the latest edits are saved before submitting for review.
      final hasDraft = _summary?.draftVersion != null;
      final payload = _buildPayload();
      if (hasDraft) {
        await _quizService.updateQuizDraft(widget.courseId, payload);
      } else {
        await _quizService.createQuizDraft(widget.courseId, payload);
      }
      await _quizService.submitQuizForReview(widget.courseId);
      if (!mounted) return;
      showTopPopup(
        context,
        'Mtihani umetumwa kwa ukaguzi wa timu ya Kreative Karakana.',
        isError: false,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Future<void> _deleteDraft() async {
    setState(() => _isSaving = true);
    try {
      await _quizService.deleteQuizDraft(widget.courseId);
      if (!mounted) return;
      showTopPopup(context, 'Rasimu imefutwa.', isError: false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuestion() {
    final questionController = TextEditingController();
    final explanationController = TextEditingController();
    final optionControllers = List.generate(4, (_) => TextEditingController());
    int selectedCorrect = 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D5C8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ongeza Swali',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D1800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(
                      labelText: 'Swali',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedCorrect = i),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedCorrect == i
                                      ? const Color(0xFFE87722)
                                      : const Color(0xFFE8D5C8),
                                  width: 2,
                                ),
                                color: selectedCorrect == i
                                    ? const Color(0xFFE87722)
                                        .withValues(alpha: 0.12)
                                    : Colors.transparent,
                              ),
                              child: selectedCorrect == i
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Color(0xFFE87722),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: optionControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Chaguo ${['A', 'B', 'C', 'D'][i]}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  TextField(
                    controller: explanationController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Maelezo (hiari) — yanaonekana baada ya kufaulu',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (questionController.text.trim().isEmpty ||
                            optionControllers
                                .any((c) => c.text.trim().isEmpty)) {
                          showTopPopup(
                              context, 'Jaza swali na majibu yote manne.');
                          return;
                        }
                        setState(() {
                          _questions.add({
                            'question': questionController.text.trim(),
                            'options': optionControllers
                                .map((controller) => controller.text.trim())
                                .toList(),
                            'correct': selectedCorrect,
                            'explanation': explanationController.text.trim(),
                          });
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE87722),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Hifadhi Swali',
                        style:
                            GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Mtihani wa Mwisho',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: _isEditing
            ? [
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: KarakanaWaveLoader(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _saveDraft,
                    child: Text(
                      'Hifadhi',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _addQuestion,
                ),
              ]
            : null,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: KarakanaWaveLoader(color: Color(0xFFE87722)));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFE87722)),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Jaribu tena')),
            ],
          ),
        ),
      );
    }

    final summary = _summary;
    final statusVersion = summary?.pendingReviewVersion ??
        summary?.activeVersion ??
        summary?.rejectedVersion;

    return Column(
      children: [
        if (statusVersion != null) _StatusBanner(version: statusVersion),
        Expanded(
          child: _isEditing
              ? _buildEditor()
              : _buildNonEditingState(summary, statusVersion),
        ),
      ],
    );
  }

  Widget _buildNonEditingState(
      QuizSummary? summary, QuizVersionSummary? statusVersion) {
    final isPendingReview = summary?.pendingReviewVersion != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPendingReview ? Icons.hourglass_top : Icons.quiz_outlined,
              size: 56,
              color: const Color(0xFFE8D5C8),
            ),
            const SizedBox(height: 16),
            Text(
              isPendingReview
                  ? 'Mtihani unasubiri ukaguzi wa timu ya Kreative Karakana.'
                  : (statusVersion != null
                      ? 'Toleo la sasa la mtihani limekamilika.'
                      : 'Bado hujatengeneza mtihani wa mwisho wa kozi hii.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF9E8070),
              ),
            ),
            const SizedBox(height: 20),
            if (!isPendingReview)
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  statusVersion != null
                      ? 'Tengeneza Toleo Jipya'
                      : 'Unda Mtihani',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE87722),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () => setState(() => _enterEditMode(null)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alama ya Kufaulu',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3D1800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kati ya ${QuizContract.minPassingScore}% na ${QuizContract.maxPassingScore}%.',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF9E8070),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: _NumberField(controller: _passingScoreController, suffix: '%'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Muda wa Kusubiri Baada ya Kushindwa',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3D1800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dakika kabla ya mwanafunzi kujaribu tena.',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF9E8070),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: _NumberField(controller: _cooldownController, suffix: 'dq'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hitajika kwa Cheti',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                  ),
                  Switch(
                    value: _requiredForCertificate,
                    activeThumbColor: const Color(0xFFE87722),
                    onChanged: (v) =>
                        setState(() => _requiredForCertificate = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFF0E4DA)),
        Expanded(
          child: _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 64,
                        color: Color(0xFFE8D5C8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hakuna Maswali Bado',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                                  const Color(0xFF1A0A00),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ongeza maswali ya mtihani.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _questions.length,
                  itemBuilder: (_, i) => _QuestionCard(
                    index: i,
                    question: _questions[i],
                    onDelete: () => setState(() => _questions.removeAt(i)),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Ongeza Swali Jipya',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE87722),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _addQuestion,
                ),
              ),
              if (_questions.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmittingReview ? null : _submitForReview,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE87722)),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isSubmittingReview
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: KarakanaWaveLoader(
                              color: Color(0xFFE87722),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Tuma kwa Ukaguzi',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE87722),
                            ),
                          ),
                  ),
                ),
              ],
              if (_summary?.draftVersion != null) ...[
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _deleteDraft,
                  child: Text(
                    'Futa Rasimu',
                    style: GoogleFonts.montserrat(color: const Color(0xFFB71C1C)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;

  const _NumberField({required this.controller, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFE87722),
      ),
      decoration: InputDecoration(
        suffix: Text(
          suffix,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF9E8070),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE87722)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = question['options'] as List<String>? ?? [];
    final correct = question['correct'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x0FC4620A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE87722),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question['question'] as String? ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFFB71C1C), size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...options.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: e.key == correct
                            ? const Color(0xFFE87722)
                            : (isDark
                                ? const Color(0xFF2A1A0A)
                                : const Color(0xFFF5E6D8)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          ['A', 'B', 'C', 'D'][e.key],
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: e.key == correct
                                ? Colors.white
                                : const Color(0xFF9E8070),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF5C3D2E),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final QuizVersionSummary version;

  const _StatusBanner({required this.version});

  @override
  Widget build(BuildContext context) {
    final presentation = QuizContract.statusPresentation(version.status);
    final isRejected = QuizContract.isRejected(version.status);
    return Container(
      width: double.infinity,
      color: Color(presentation.colorValue).withValues(alpha: 0.08),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(presentation.colorValue),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  presentation.label,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Toleo ${version.versionNumber}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF9E8070),
                ),
              ),
            ],
          ),
          if (isRejected && (version.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              version.rejectionReason!,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF5C3D2E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
