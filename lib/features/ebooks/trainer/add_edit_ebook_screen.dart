import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
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
  bool _saving = false;

  Future<void> _pickCover() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x == null) return;
    setState(() => _coverPath = x.path);
  }

  Future<void> _pickEpub() async {
    const typeGroup = XTypeGroup(label: 'epub', extensions: ['epub']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    setState(() => _epubPath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.ebookId == null && (_coverPath == null || _epubPath == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover image na EPUB vinahitajika.')));
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.ebookId == null) {
        await _service.createEbook(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: _price.text.trim(),
          coverImagePath: _coverPath!,
          epubFilePath: _epubPath!,
        );
      } else {
        await _service.updateEbook(
          id: widget.ebookId!,
          data: {
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'price': _price.text.trim(),
          },
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient().parseError(e))));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.ebookId == null ? 'Ongeza eBook' : 'Hariri eBook')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (TZS)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final p = int.tryParse(v.trim());
                if (p == null || p < 0) return 'Must be a positive number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickCover,
              icon: const Icon(Icons.image_outlined),
              label: Text(_coverPath == null ? 'Pick cover image' : 'Cover selected'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickEpub,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(_epubPath == null ? 'Pick EPUB file' : 'EPUB selected'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
