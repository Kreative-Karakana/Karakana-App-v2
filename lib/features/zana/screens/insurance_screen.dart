import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../services/zana_lead_capture_service.dart';
import '../utils/lead_capture_validators.dart';

class InsuranceScreen extends StatefulWidget {
  final ZanaLeadCaptureService? leadCaptureService;

  const InsuranceScreen({
    super.key,
    this.leadCaptureService,
  });

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final ZanaLeadCaptureService _leadCaptureService;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _submitError;
  String? _nameServerError;
  String? _phoneServerError;

  static const _color = Color(0xFF3D1800);

  @override
  void initState() {
    super.initState();
    _leadCaptureService =
        widget.leadCaptureService ?? ApiZanaLeadCaptureService();
  }

  Future<void> _submitLead() async {
    if (_isSubmitting || _isSubmitted) return;

    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _focusFirstInvalidField();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await _leadCaptureService.captureLead(
        name: _nameController.text.trim(),
        phone: LeadCaptureValidators.normalizePhone(_phoneController.text),
        source: 'insurance',
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      final exception = error is ZanaLeadCaptureException ? error : null;
      final fieldErrors = exception?.fieldErrors ?? const <String, String>{};
      setState(() {
        _isSubmitting = false;
        _nameServerError = fieldErrors['name'];
        _phoneServerError = fieldErrors['phone'];
        _submitError = fieldErrors.isEmpty
            ? exception?.message ??
                'Imeshindikana kutuma taarifa. Tafadhali jaribu tena.'
            : null;
      });
      if (fieldErrors.isNotEmpty) {
        _formKey.currentState?.validate();
        _focusFirstInvalidField();
      }
    }
  }

  void _focusFirstInvalidField() {
    final nameError =
        _nameServerError ?? LeadCaptureValidators.name(_nameController.text);
    if (nameError != null) {
      _nameFocusNode.requestFocus();
      return;
    }
    _phoneFocusNode.requestFocus();
  }

  void _clearNameServerError(String _) {
    if (_nameServerError == null) return;
    setState(() => _nameServerError = null);
  }

  void _clearPhoneServerError(String _) {
    if (_phoneServerError == null) return;
    setState(() => _phoneServerError = null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isNarrow = mediaQuery.size.width <= 375;
    final heroIconSize = isLandscape ? 72.0 : (isNarrow ? 80.0 : 88.0);

    const products = [
      [
        Icons.favorite_outline,
        'Bima ya Afya',
        'Linda wewe na familia yako dhidi ya gharama za matibabu',
      ],
      [
        Icons.store_outlined,
        'Bima ya Mali',
        'Hifadhi biashara na mali yako dhidi ya hasara na majanga',
      ],
      [
        Icons.people_outline,
        'Bima ya Maisha',
        'Tumia akili unapojua familia yako iko salama wakati wowote',
      ],
      [
        Icons.phone_android_outlined,
        'Bima ya Vifaa',
        'Linda simu, kompyuta, na vifaa vingine vya biashara',
      ],
    ];

    const steps = [
      ['1', 'Chagua mpango', 'Chagua bima inayofaa mahitaji yako'],
      ['2', 'Lipa kidijitali', 'Lipa kwa M-Pesa au benki kwa haraka'],
      ['3', 'Pumzika', 'Uko salama — tutashughulikia madai yako'],
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _color,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Bima ya Biashara',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: Column(
          children: [
            // ── Hero header ──────────────────────────────────────────────
            Container(
              key: const Key('insurance-hero'),
              constraints: BoxConstraints(
                minHeight: isLandscape ? 210 : 260,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 16 : 24,
                vertical: isLandscape ? 20 : 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.zanaGradient,
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: heroIconSize,
                            height: heroIconSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.security_outlined,
                              color: Colors.white,
                              size: heroIconSize * 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bima ya Biashara',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Linda biashara yako dhidi ya hatari yoyote',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
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
                              style: GoogleFonts.montserrat(
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
                  ),
                ],
              ),
            ),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isNarrow ? 16 : 24,
                    24,
                    isNarrow ? 16 : 24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Description ───────────────────────────────────────
                      Text(
                        'Kwa Nini Bima?',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Biashara yoyote inaweza kukabiliana na hatari zisizotarajiwa — moto, wizi, magonjwa, au majanga ya asili. Bima inahakikisha hata wakati mgumu haufutu jasho lako la miaka.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Products ──────────────────────────────────────────
                      Text(
                        'Aina za Bima',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...products.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A5A1A1A),
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
                                  color: AppColors.surfaceWarm,
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
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item[2] as String,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: AppColors.textTertiary,
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

                      // ── How it works ──────────────────────────────────────
                      Text(
                        'Jinsi Inavyofanya Kazi',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...steps.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: _color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      step[0],
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step[1],
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        step[2],
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          color: AppColors.textTertiary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 8),

                      // ── Interest form ─────────────────────────────────────
                      if (!_isSubmitted) ...[
                        Text(
                          'Kupata Bima Mapema',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Jisajili kupata taarifa na bei maalum za awali.',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            children: [
                              TextFormField(
                                key: const Key('insurance-name-field'),
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                enabled: !_isSubmitting,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.name],
                                onChanged: _clearNameServerError,
                                onFieldSubmitted: (_) =>
                                    _phoneFocusNode.requestFocus(),
                                decoration: InputDecoration(
                                  labelText: 'Jina Lako',
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: _color,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: _color,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    _nameServerError ??
                                    LeadCaptureValidators.name(value),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('insurance-phone-field'),
                                controller: _phoneController,
                                focusNode: _phoneFocusNode,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\-() ]'),
                                  ),
                                  LengthLimitingTextInputFormatter(20),
                                ],
                                onChanged: _clearPhoneServerError,
                                onFieldSubmitted: (_) => _submitLead(),
                                decoration: InputDecoration(
                                  labelText: 'Nambari ya Simu',
                                  prefixIcon: const Icon(
                                    Icons.phone_outlined,
                                    color: _color,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: _color,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    _phoneServerError ??
                                    LeadCaptureValidators.phone(value),
                              ),
                              const SizedBox(height: 24),
                              if (_submitError != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  container: true,
                                  label: 'Hitilafu ya kutuma taarifa',
                                  child: Container(
                                    key: const Key('insurance-submit-error'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorLight,
                                      borderRadius: BorderRadius.circular(14),
                                      border:
                                          Border.all(color: AppColors.error),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _submitError!,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            color: AppColors.error,
                                            height: 1.4,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        TextButton(
                                          key: const Key(
                                            'insurance-submit-retry-button',
                                          ),
                                          onPressed: _submitLead,
                                          child: const Text('Jaribu tena'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  key: const Key('insurance-submit-button'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _color,
                                    foregroundColor: Colors.white,
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _isSubmitting ? null : _submitLead,
                                  child: Semantics(
                                    liveRegion: _isSubmitting,
                                    label: _isSubmitting
                                        ? 'Inatuma taarifa zako'
                                        : 'Niarifu bima inapozinduliwa',
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isSubmitting) ...[
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: KarakanaWaveLoader(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Flexible(
                                          child: Text(
                                            _isSubmitting
                                                ? 'Inatuma...'
                                                : 'Niarifu Ninapozinduliwa',
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Semantics(
                          liveRegion: true,
                          container: true,
                          label:
                              'Umesajiliwa. Tutakuwasiliana nawe bima inapopatikana.',
                          child: Container(
                            key: const Key('insurance-submit-success'),
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
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
                                  style: GoogleFonts.montserrat(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Asante! Tutakuwasiliana nawe mara Bima inapopatikana.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
