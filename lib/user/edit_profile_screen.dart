import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Service/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _profilePicBase64;
  bool _isLoading = true;
  String? _initialName;
  String? _initialPic;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final name = await authService.getUserName();
    final pic = await authService.getProfilePic();
    if (mounted) {
      setState(() {
        _nameController.text = name ?? '';
        _profilePicBase64 = pic;
        _initialName = name;
        _initialPic = pic;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() {
        _profilePicBase64 = base64;
      });
    }
  }

  Future<void> _saveChanges() async {
    bool nameChanged = _nameController.text.trim() != (_initialName ?? '');
    bool picChanged = _profilePicBase64 != _initialPic;

    if (nameChanged) {
      final error =
          await authService.updateUserName(_nameController.text.trim());
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating name: $error')),
        );
        return;
      }
    }

    if (picChanged && _profilePicBase64 != null) {
      final error = await authService.updateProfilePic(_profilePicBase64!);
      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $error')),
        );
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    Navigator.pop(context, true); // Return true to indicate update
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: _profilePicBase64 != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(_profilePicBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePicBase64 == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickImage,
              child: const Text('Change Profile Picture'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
