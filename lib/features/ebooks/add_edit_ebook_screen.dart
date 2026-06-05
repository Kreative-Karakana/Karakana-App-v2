import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import 'services/ebook_service.dart';

class AddEditEbookScreen extends StatefulWidget {
  final int? ebookId;
  const AddEditEbookScreen({super.key, this.ebookId});

  @override
  State<AddEditEbookScreen> createState() => _AddEditEbookScreenState();
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = _formatter.format(int.parse(digitsOnly));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _AddEditEbookScreenState extends State<AddEditEbookScreen> {
  final _service = EbookService();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  String? _coverPath;
  Uint8List? _ebookBytes;
  String? _coverName;
  String? _ebookName;
  bool _saving = false;
  String get _normalizedPrice => _price.text.replaceAll(',', '').trim();

  Future<void> _pickCover() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x == null) return;
    setState(() {
      _coverPath = x.path;
      _coverName = x.name;
    });
  }

  Future<void> _pickPdf() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
        mimeTypes: ['application/pdf'],
        uniformTypeIdentifiers: ['com.adobe.pdf'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final fileName = file.name;
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tafadhali chagua faili la PDF pekee.',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
        return;
      }
      Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        if (file.path.isEmpty) rethrow;
        bytes = await File(file.path).readAsBytes();
      }
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Faili lililochaguliwa haliwezi kusomwa. Jaribu tena.',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
        return;
      }
      setState(() {
        _ebookBytes = bytes;
        _ebookName = fileName;
      });
    } catch (_) {
      debugPrint('[eBook PDF] Picker failed.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hitilafu ya kuchagua PDF. Jaribu tena.',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.ebookId == null &&
        (_coverPath == null || _ebookBytes == null || _ebookName == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Picha ya jalada na faili la PDF vinahitajika.',
              style: GoogleFonts.montserrat()),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      if (widget.ebookId == null) {
        await _service.createEbook(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: _normalizedPrice,
          coverImagePath: _coverPath ?? '',
          ebookFileBytes: _ebookBytes!,
          ebookFileName: _ebookName!,
        );
      } else {
        await _service.updateEbook(
          id: widget.ebookId!,
          data: {
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'price': _normalizedPrice,
          },
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('eBook imehifadhiwa kikamilifu!',
                style: GoogleFonts.montserrat()),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
        context.go('/trainer/ebooks');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient().parseError(e),
                style: GoogleFonts.montserrat()),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF9E8070)),
      prefixIcon: Icon(icon, color: const Color(0xFFE87722), size: 20),
      filled: true,
      fillColor: const Color(0xFFFFF8F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB71C1C)),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D5C8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE87722).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFilePicker({
    required String label,
    required String hint,
    required IconData icon,
    required String? selectedName,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE87722).withValues(alpha: 0.06)
              : const Color(0xFFFFF8F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE87722).withValues(alpha: 0.5)
                : const Color(0xFFE8D5C8),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE87722).withValues(alpha: 0.12)
                    : const Color(0xFFE8D5C8).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? Icons.check_circle_outline : icon,
                color: isSelected
                    ? const Color(0xFFE87722)
                    : const Color(0xFF9E8070),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D1800),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedName ?? hint,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: isSelected
                          ? const Color(0xFFE87722)
                          : const Color(0xFF9E8070),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isSelected
                  ? const Color(0xFFE87722)
                  : const Color(0xFFBDA99C),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ebookId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A0A00) : const Color(0xFFFFF8F4);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEdit ? 'Hariri eBook' : 'Ongeza eBook Mpya',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(context).viewPadding.bottom + 24,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8D5C8)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE87722).withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
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
                    child: const Icon(Icons.menu_book_outlined,
                        color: Color(0xFFE87722), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Hariri eBook' : 'Ongeza eBook Mpya',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3D1800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit
                              ? 'Sasisha maelezo na uandae eBook kwa ukaguzi.'
                              : 'Jaza maelezo, kisha pakia jalada na faili la eBook.',
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            color: const Color(0xFF7B3A10),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maelezo ya eBook',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9E8070),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _title,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF1A0A00)),
                    decoration:
                        _inputDecoration('Jina la eBook', Icons.title_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Jina linahitajika'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF1A0A00)),
                    decoration:
                        _inputDecoration('Maelezo', Icons.description_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Maelezo yanahitajika'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorInputFormatter(),
                    ],
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: const Color(0xFF1A0A00)),
                    decoration:
                        _inputDecoration('Bei (TZS)', Icons.sell_outlined),
                    validator: (v) {
                      final normalized = (v ?? '').replaceAll(',', '').trim();
                      if (normalized.isEmpty) {
                        return 'Bei inahitajika';
                      }
                      final p = int.tryParse(normalized);
                      if (p == null || p < 0) {
                        return 'Ingiza nambari sahihi';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faili za eBook',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9E8070),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilePicker(
                    label: 'Picha ya Jalada',
                    hint: 'Bonyeza kuchagua picha (JPG/PNG)',
                    icon: Icons.image_outlined,
                    selectedName: _coverName,
                    onTap: _pickCover,
                  ),
                  const SizedBox(height: 12),
                  _buildFilePicker(
                    label: 'Faili la PDF',
                    hint: 'Bonyeza kuchagua faili (.pdf)',
                    icon: Icons.file_open_outlined,
                    selectedName: _ebookName,
                    onTap: _pickPdf,
                  ),
                ],
              ),
            ),
            if (_coverPath != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_coverPath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_saving) ...[
              const LinearProgressIndicator(
                color: Color(0xFFE87722),
                backgroundColor: Color(0xFFE8D5C8),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Inapakia eBook...',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: Icon(
                  _saving
                      ? Icons.hourglass_top_rounded
                      : Icons.cloud_upload_outlined,
                  size: 20,
                ),
                label: Text(
                  _saving
                      ? 'Inapakia...'
                      : (isEdit ? 'Hifadhi Mabadiliko' : 'Pakia eBook'),
                  style: GoogleFonts.montserrat(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE87722),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFE87722).withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
