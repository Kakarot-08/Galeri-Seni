import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:artilier_demo/Service/auth_service.dart';
import 'package:artilier_demo/View/login_screen.dart';
import 'admin_detail_screen.dart';
import 'admin_history.dart';
import 'package:artilier_demo/config.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _screens = [
     const _AdminHomeTab(),
     const AdminHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/artilier.png',
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _currentIndex == 0 ? 'Artwork review' : 'History',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              // Notification action
            },
          ),
          if (_currentIndex == 0) // Only show logout on Home tab? Or both? Screenshot shows Bell on History.
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
              }
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
           setState(() {
             _currentIndex = index;
           });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class _AdminHomeTab extends StatefulWidget {
  const _AdminHomeTab();

  @override
  State<_AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<_AdminHomeTab> {
  late Future<List<Map<String, dynamic>>> _pendingPhotosFuture;

  Future<List<Map<String, dynamic>>> _fetchPendingPhotos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/photos.php?status=pending'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((photo) => {
                  'id': photo['id'].toString(),
                  'title': photo['title'],
                  'image': photo['image_data'],
                  'uploader': photo['uploader_email'],
                  'uploaderName': photo['uploader_name'] ?? photo['uploader_email'].split('@')[0],
                  'uploaderUid': photo['uploader_uid'],
                  'status': photo['status'],
                  'highestBid': photo['highest_bid']?.toString() ?? '150.000', // Default if null for verify
                  'created_at': photo['created_at'],
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching pending photos: $e');
    }
    return [];
  }
  
  String _formatDate(String? dateStr) {
     if (dateStr == null) return '';
     try {
       return DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
     } catch(_) {
       return dateStr;
     }
  }

  @override
  void initState() {
    super.initState();
    _pendingPhotosFuture = _fetchPendingPhotos();
  }

  @override
  Widget build(BuildContext context) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingPhotosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending artworks', style: TextStyle(color: Colors.grey)));
          }

          final pendingPhotos = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingPhotos.length,
            itemBuilder: (context, index) {
              final photo = pendingPhotos[index];
              return GestureDetector(
                onTap: () async {
                   final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminDetailScreen(
                            photo: photo.cast<String, String>(), index: index),
                      ),
                    );
                    if (result == true) { // If approved/rejected
                         setState(() {
                           _pendingPhotosFuture = _fetchPendingPhotos();
                         });
                    }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    // Blue border for first item or highlighting? 
                    // Screenshot shows first item has blue border.
                    border: index == 0 ? Border.all(color: Colors.blue, width: 2) : null,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Image.memory(
                            base64Decode(photo['image']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              photo['uploader'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(photo['created_at']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           Text(
                              '\$${photo['highestBid']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  }
}
