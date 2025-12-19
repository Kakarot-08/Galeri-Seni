import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:artilier_demo/View/login_screen.dart';
import '../Service/auth_service.dart';
import 'package:artilier_demo/user/edit_profile_screen.dart';
import 'package:artilier_demo/user/my_artworks_screen.dart';
import 'package:artilier_demo/user/liked_photos_screen.dart';
import 'package:artilier_demo/user/transaction_history.dart';
import 'package:artilier_demo/user/notification_screen.dart';
import 'package:artilier_demo/user/balance_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();
  String? _name;
  String? _email;
  String? _profilePicBase64;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await authService.getUserName();
    final pic = await authService.getProfilePic();
    final user = authService.getCurrentUser();
    
    if (mounted) {
      setState(() {
        _name = name ?? user?.email?.split('@')[0] ?? 'User';
        _email = user?.email ?? '';
        _profilePicBase64 = pic;
        _isLoading = false;
      });
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label, // Optional label, screenshot doesn't show labels but valid to guess
          // Screenshot just shows numbers: 12  48  5
          // I will emulate screenshot: No text labels below? Or maybe I misread.
          // Screenshot: "12   48   5" centered.
          // I will just return Text(value) styled.
        ),
      ],
    );
  }

  Widget _buildStatNumber(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Don't show back button if in Tab
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
             Image.asset(
              'assets/artilier.png',
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Profile',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.black),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  image: _profilePicBase64 != null
                      ? DecorationImage(
                          image: MemoryImage(base64Decode(_profilePicBase64!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePicBase64 == null
                    ? Center(
                        child: Text(
                          _name?.substring(0, 1).toUpperCase() ?? 'A',
                          style: const TextStyle(fontSize: 40, color: Colors.black54),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              _name ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 8),
            
            // Email
            Text(
              _email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const SizedBox(height: 10),
            
            // Balance Button (New)
            _buildMenuItem("Balance", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BalanceScreen()),
              );
            }),
            
            
            // Menu
            _buildMenuItem("Edit Profile", () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              if (result == true) {
                _loadProfile();
              }
            }),
            _buildMenuItem("My Artworks", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyArtworksScreen()),
              );
            }),
            _buildMenuItem("Favorites", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LikedPhotosScreen()),
              );
            }),
            _buildMenuItem("Settings", () {}),
            _buildMenuItem("Help & Support", () {}),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await authService.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
