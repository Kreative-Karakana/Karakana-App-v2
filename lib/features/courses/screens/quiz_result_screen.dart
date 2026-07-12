import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../utils/quiz_contract.dart';

class QuizResultScreen extends StatefulWidget {
  final int courseId;
  final int attemptId;

  const QuizResultScreen({
    super.key,
    required this.courseId,
    required this.attemptId,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final _quizService = QuizService();
  bool _isLoading = true;
  String? _error;
  QuizAttemptResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _quizService.getAttemptResult(widget.attemptId);
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        automaticallyImplyLeading: false,
        title: Text(
          'Matokeo ya Mtihani',
          style: GoogleFonts.montserrat(
            fontSize: AppTextStyles.bodyLarge.fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: KarakanaWaveLoader(color: Color(0xFFE87722)));
    }
    if (_error != null || _result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE87722)),
              const SizedBox(height: 12),
              Text(_error ?? 'Hatukuweza kupata matokeo.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Jaribu tena')),
            ],
          ),
        ),
      );
    }

    final result = _result!;
    final retryText = QuizContract.formatCooldownRemaining(result.retryAvailableAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultBanner(result: result, retryText: retryText),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Majibu Yako',
            style: GoogleFonts.montserrat(
              fontSize: AppTextStyles.bodyLarge.fontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3D1800),
            ),
          ),
          const SizedBox(height: 12),
          ...result.answers.map((a) => _AnswerCard(answer: a)),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/course/${widget.courseId}/classroom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE87722),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text(
                'Rudi Kwenye Darasa',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final QuizAttemptResult result;
  final String? retryText;

  const _ResultBanner({required this.result, required this.retryText});

  @override
  Widget build(BuildContext context) {
    final passed = result.passed;
    final color = passed ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            passed ? Icons.emoji_events : Icons.sentiment_dissatisfied_outlined,
            size: 48,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            passed ? 'Hongera! Umefaulu' : 'Umeshindwa Mtihani',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Alama yako: ${result.score?.round() ?? 0}% '
            '(kufaulu: ${result.passingPercentageSnapshot}%)',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF5C3D2E),
            ),
          ),
          if (!passed && retryText != null) ...[
            const SizedBox(height: 10),
            Text(
              retryText!,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 13, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final QuizAnswerResult answer;

  const _AnswerCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    final showCorrectAnswer = answer.options != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: answer.isCorrect
              ? const Color(0xFF2E7D32).withValues(alpha: 0.3)
              : const Color(0xFFB71C1C).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                answer.isCorrect ? Icons.check_circle : Icons.cancel_outlined,
                size: 18,
                color: answer.isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.content,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D1800),
                  ),
                ),
              ),
            ],
          ),
          if (showCorrectAnswer) ...[
            const SizedBox(height: 8),
            ...answer.options!.map((option) {
              final isSelected = option.id == answer.selectedOptionId;
              final isCorrectOption = option.id == answer.correctOptionId;
              Color? bg;
              if (isCorrectOption) {
                bg = const Color(0xFF2E7D32).withValues(alpha: 0.1);
              } else if (isSelected) {
                bg = const Color(0xFFB71C1C).withValues(alpha: 0.08);
              }
              return Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isCorrectOption)
                      const Icon(Icons.check, size: 14, color: Color(0xFF2E7D32))
                    else if (isSelected)
                      const Icon(Icons.close, size: 14, color: Color(0xFFB71C1C))
                    else
                      const SizedBox(width: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        option.text,
                        style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF5C3D2E)),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if ((answer.explanation ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                answer.explanation!,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF9E8070),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
