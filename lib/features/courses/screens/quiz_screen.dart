import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_attempt_provider.dart';
import '../utils/quiz_contract.dart';

class QuizScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const QuizScreen(
      {super.key, required this.courseId, required this.courseTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuizAttemptProvider>();
      provider.reset();
      provider.loadAvailability(widget.courseId);
      provider.loadHistory(widget.courseId);
    });
  }

  Future<void> _submit(QuizAttemptProvider provider) async {
    final ok = await provider.submit();
    if (!mounted) return;
    if (ok && provider.result != null) {
      context.pushReplacement(
        '/course/${widget.courseId}/quiz/result/${provider.result!.id}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Mtihani wa Mwisho',
          style: GoogleFonts.montserrat(
            fontSize: AppTextStyles.bodyLarge.fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<QuizAttemptProvider>(
          builder: (context, provider, _) {
            if (provider.attempt != null &&
                provider.attempt!.status == 'in_progress') {
              return _AttemptForm(
                provider: provider,
                onSubmit: () => _submit(provider),
              );
            }
            return _AvailabilityView(
              courseId: widget.courseId,
              provider: provider,
            );
          },
        ),
      ),
    );
  }
}

class _AvailabilityView extends StatelessWidget {
  final int courseId;
  final QuizAttemptProvider provider;

  const _AvailabilityView({required this.courseId, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingAvailability) {
      return const Center(child: KarakanaWaveLoader(color: Color(0xFFE87722)));
    }

    final availability = provider.availability;
    if (availability == null || provider.availabilityError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            provider.availabilityError ??
                'Hatukuweza kupata taarifa za mtihani.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: const Color(0xFF5C3D2E)),
          ),
        ),
      );
    }

    if (!availability.quizAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined,
                  size: 56, color: Color(0xFFE8D5C8)),
              const SizedBox(height: 16),
              Text(
                'Mtihani wa kozi hii haupatikani kwa sasa.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: const Color(0xFF5C3D2E)),
              ),
            ],
          ),
        ),
      );
    }

    final cooldownText = QuizContract.formatCooldownRemaining(
      availability.cooldownExpiresAt,
    );
    final canStart = availability.lessonsComplete && cooldownText == null;
    final hasInProgress = availability.inProgressAttemptId != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0FC4620A),
                    blurRadius: 10,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mtihani wa Mwisho wa Kozi',
                  style: GoogleFonts.montserrat(
                    fontSize: AppTextStyles.h4.fontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D1800),
                  ),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.emoji_events_outlined,
                  text: 'Alama ya kufaulu: ${availability.passingScore ?? 70}%',
                ),
                if (availability.requiredForCertificate)
                  const _InfoRow(
                    icon: Icons.workspace_premium_outlined,
                    text: 'Lazima ufaulu ili upate cheti cha kozi hii.',
                  ),
                if (availability.attemptCount > 0)
                  _InfoRow(
                    icon: Icons.history,
                    text: 'Umejaribu mara ${availability.attemptCount}.'
                        '${availability.isPassed ? ' Tayari umefaulu.' : ''}',
                  ),
                if (!availability.lessonsComplete)
                  const _InfoRow(
                    icon: Icons.error_outline,
                    text:
                        'Kamilisha masomo yote ya kozi kabla ya kuanza mtihani.',
                    color: Color(0xFFB71C1C),
                  ),
                if (cooldownText != null)
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    text: cooldownText,
                    color: const Color(0xFFB71C1C),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canStart && !provider.isStarting
                  ? () => provider.startOrResume(courseId)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE87722),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
              ),
              child: provider.isStarting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: KarakanaWaveLoader(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      hasInProgress ? 'Endelea Mtihani' : 'Anza Mtihani',
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          if (provider.startErrorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              QuizContract.reasonCodeMessage(
                provider.startErrorCode,
                fallback: provider.startErrorMessage,
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: const Color(0xFFB71C1C), fontSize: 13),
            ),
          ],
          if (provider.history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Historia ya Majaribio',
              style: GoogleFonts.montserrat(
                fontSize: AppTextStyles.bodyLarge.fontSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D1800),
              ),
            ),
            const SizedBox(height: 10),
            ...provider.history.map((a) => _HistoryTile(attempt: a)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? const Color(0xFF9E8070)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: color ?? const Color(0xFF5C3D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final QuizAttemptSummary attempt;

  const _HistoryTile({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final passed = attempt.passed == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0E4DA)),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel_outlined,
            size: 18,
            color: passed ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jaribio ${attempt.attemptNumber}',
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: const Color(0xFF3D1800)),
            ),
          ),
          if (attempt.score != null)
            Text(
              '${attempt.score!.round()}%',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    passed ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttemptForm extends StatelessWidget {
  final QuizAttemptProvider provider;
  final VoidCallback onSubmit;

  const _AttemptForm({required this.provider, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final attempt = provider.attempt!;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: attempt.questions.length,
            itemBuilder: (context, index) {
              final question = attempt.questions[index];
              final selected = provider.answers[question.id];
              return _QuestionForm(
                index: index,
                question: question,
                selectedOptionId: selected,
                onSelect: (optionId) =>
                    provider.selectOption(question.id, optionId),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                if (provider.saveError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Imeshindikana kuhifadhi jibu: ${provider.saveError}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFFB71C1C),
                      ),
                    ),
                  ),
                if (provider.submitError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      provider.submitError!,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFFB71C1C),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        provider.allQuestionsAnswered && !provider.isSubmitting
                            ? onSubmit
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE87722),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: provider.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: KarakanaWaveLoader(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Wasilisha',
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionForm extends StatelessWidget {
  final int index;
  final QuizQuestionModel question;
  final int? selectedOptionId;
  final ValueChanged<int> onSelect;

  const _QuestionForm({
    required this.index,
    required this.question,
    required this.selectedOptionId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0FC4620A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.content}',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D1800),
            ),
          ),
          const SizedBox(height: 10),
          ...question.options.map((option) {
            final isSelected = selectedOptionId == option.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => onSelect(option.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE87722).withValues(alpha: 0.1)
                        : (isDark
                            ? const Color(0xFF2A1A0A)
                            : const Color(0xFFF5E6D8)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE87722)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                        color: isSelected
                            ? const Color(0xFFE87722)
                            : const Color(0xFF9E8070),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option.text,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF3D1800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
