import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';
import '../../../widgets/common/top_popup.dart';

class QuizManagerScreen extends StatefulWidget {
  final int courseId;

  const QuizManagerScreen({super.key, required this.courseId});

  @override
  State<QuizManagerScreen> createState() => _QuizManagerScreenState();
}

class _QuizManagerScreenState extends State<QuizManagerScreen> {
  final List<Map<String, dynamic>> _questions = [];
  final TextEditingController _passingScoreController =
      TextEditingController(text: '70');
  bool _isSaving = false;

  @override
  void dispose() {
    _passingScoreController.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    if (_questions.isEmpty) {
      showTopPopup(context, 'Ongeza maswali angalau moja kwanza.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final passingScore =
          int.tryParse(_passingScoreController.text.trim()) ?? 70;
      await ApiClient().dio.post(
        '/api/v1/courses/${widget.courseId}/quiz/',
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
      if (!mounted) return;
      showTopPopup(context, 'Maswali yamehifadhiwa!', isError: false);
    } catch (e) {
      if (!mounted) return;
      showTopPopup(context, ApiClient().parseError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addQuestion() {
    final questionController = TextEditingController();
    final optionControllers =
        List.generate(4, (_) => TextEditingController());
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
                        onTap: () => setModalState(() => selectedCorrect = i),
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
                                ? const Color(0xFFE87722).withValues(alpha: 0.12)
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (questionController.text.trim().isEmpty ||
                        optionControllers.any((c) => c.text.trim().isEmpty)) {
                      showTopPopup(context, 'Jaza swali na majibu yote manne.');
                      return;
                    }
                    setState(() {
                      _questions.add({
                        'question': questionController.text.trim(),
                        'options': optionControllers
                            .map((controller) => controller.text.trim())
                            .toList(),
                        'correct': selectedCorrect,
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
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Majaribio',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
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
              onPressed: _saveQuiz,
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
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(16),
            child: Row(
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
                        'Wanafunzi wanahitaji kupata alama hii kufaulu.',
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
                  child: TextFormField(
                    controller: _passingScoreController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE87722),
                    ),
                    decoration: InputDecoration(
                      suffix: Text(
                        '%',
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF0E4DA)),
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
                            color: Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1A0A00),
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
                    itemBuilder: (_, i) {
                      final q = _questions[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0FC4620A),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
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
                                      '${i + 1}',
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
                                    q['question'] as String? ?? '',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF3D1800),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFB71C1C),
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _questions.removeAt(i)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...((q['options'] as List<String>? ?? [])
                                .asMap()
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: e.key ==
                                                    (q['correct'] as int? ?? 0)
                                                ? const Color(0xFFE87722)
                                                : (isDark ? const Color(0xFF2A1A0A) : const Color(0xFFF5E6D8)),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              ['A', 'B', 'C', 'D'][e.key],
                                              style: GoogleFonts.montserrat(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: e.key ==
                                                        (q['correct'] as int? ??
                                                            0)
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
                                  ),
                                )
                                .toList()),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }
}


