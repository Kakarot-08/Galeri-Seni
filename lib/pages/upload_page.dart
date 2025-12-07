import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../main.dart';
import '../database_helper.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedFileName;
  bool _isUploading = false;

  bool get _hasImage => _selectedImage != null || _selectedImageBytes != null;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // For web: read bytes directly
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedFileName = image.name;
            _selectedImage = null;
          });
        } else {
          // For mobile/desktop: use file
          setState(() {
            _selectedImage = File(image.path);
            _selectedFileName = image.name;
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> _savePhoto() async {
    if ((_selectedImage == null && _selectedImageBytes == null) || _titleController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih gambar dan masukkan judul')),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      late Uint8List bytes;
      late String fileName;
      
      if (kIsWeb) {
        bytes = _selectedImageBytes!;
        fileName = _selectedFileName!;
        print('Web: Saving image with ${bytes.length} bytes');
      } else {
        bytes = await _selectedImage!.readAsBytes();
        fileName = path.basename(_selectedImage!.path);
        print('Mobile: Saving image with ${bytes.length} bytes');
      }
      
      final photoId = await DatabaseHelper.instance.createPhoto(
        title: _titleController.text.trim(),
        fileName: fileName,
        imageData: bytes.toList(),
      );
      print('Photo saved with ID: $photoId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil disimpan!')),
        );
      }

      _titleController.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedFileName = null;
        _isUploading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menyimpan foto: $e')),
        );
      }
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AtelierScaffold(
      currentRoute: '/upload',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Karya',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Karya',
                      hintText: 'Judul yang indah',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Pilih Gambar',
                      hintText: _selectedFileName ?? 'Belum ada file dipilih',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.file_upload_outlined),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _hasImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          !_hasImage
                              ? 'Pratinjau akan muncul di sini.'
                              : 'File: $_selectedFileName',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isUploading ? null : _savePhoto,
                        child: _isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Simpan'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isUploading ? null : () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        },
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
