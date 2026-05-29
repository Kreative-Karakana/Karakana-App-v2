import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../services/ebook_service.dart';

class AddEditEbookScreen extends StatefulWidget {
  final int? ebookId;

  const AddEditEbookScreen({super.key, this.ebookId});

  @override
  State<AddEditEbookScreen> createState() => _AddEditEbookScreenState();
}

class _AddEditEbookScreenState extends State<AddEditEbookScreen> {
  final _service = EbookService();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();

  String? _coverPath;
  String? _epubPath;
  String? _coverName;
  String? _epubName;
  bool _saving = false;

  bool get _isEdit => widget.ebookId != null;

  Future<void> _pickCover() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (x == null) return;
    setState(() {
      _coverPath = x.path;
      _coverName = x.name;
    });
  }

  Future<void> _pickEpub() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'eBook files',
          extensions: ['epub', 'pdf'],
          mimeTypes: [
            'application/epub+zip',
            'application/pdf',
            'application/octet-stream',
            '*/*',
          ],
        ),
      ],
    );
    if (file == null) return;
    setState(() {
      _epubPath = file.path;
      _epubName = file.name;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && (_coverPath == null || _epubPath == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Picha ya jalada na faili la eBook vinahitajika.',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await _service.updateEbook(
          id: widget.ebookId!,
          data: {
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'price': _price.text.trim(),
          },
        );
      } else {
        await _service.createEbook(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: _price.text.trim(),
          coverImagePath: _coverPath ?? '',
          epubFilePath: _epubPath ?? '',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'eBook imehaririwa kikamilifu!'
                : 'eBook imehifadhiwa kikamilifu!',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ApiClient().parseError(e), style: GoogleFonts.montserrat()),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
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
      labelStyle: GoogleFonts.montserrat(
        fontSize: 13,
        color: const Color(0xFF9E8070),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFFE87722), size: 20),
      filled: true,
      fillColor: const Color(0xFFFFF8F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE87722), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(12),
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

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFF8F4);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEdit ? 'Hariri eBook' : 'Ongeza eBook',
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
                const Icon(Icons.menu_book_outlined,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'eBook',
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
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
                          _isEdit
                              ? 'Hariri eBook iliyopo'
                              : 'Tengeneza eBook mpya',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF3D1800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEdit
                              ? 'Sasisha taarifa na uihifadhi upya.'
                              : 'Weka maelezo, chagua jalada, kisha pakia faili.',
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            color: const Color(0xFF7B3A10),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _statusChip(
                              _isEdit ? 'Hariri' : 'Mpya',
                              const Color(0xFFE87722),
                            ),
                            _statusChip('Jalada', const Color(0xFF3D1800)),
                            _statusChip('EPUB / PDF', const Color(0xFF9E8070)),
                          ],
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
                      fontSize: 14,
                      color: const Color(0xFF1A0A00),
                    ),
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
                      fontSize: 14,
                      color: const Color(0xFF1A0A00),
                    ),
                    decoration: _inputDecoration(
                      'Maelezo',
                      Icons.description_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Maelezo yanahitajika'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF1A0A00),
                    ),
                    decoration:
                        _inputDecoration('Bei (TZS)', Icons.sell_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bei inahitajika';
                      }
                      final p = int.tryParse(v.trim());
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
                    label: 'Faili la EPUB / PDF',
                    hint: 'Bonyeza kuchagua faili la eBook',
                    icon: Icons.file_open_outlined,
                    selectedName: _epubName,
                    onTap: _pickEpub,
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
                  'Inahifadhi eBook...',
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
                      ? 'Inahifadhi...'
                      : (_isEdit ? 'Hifadhi Mabadiliko' : 'Pakia eBook'),
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE87722),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFE87722).withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
