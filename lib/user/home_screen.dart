import 'dart:convert';
import 'package:artilier_demo/user/photo_detail_screen.dart';
import 'package:artilier_demo/user/liked_photos_screen.dart';
import 'package:flutter/material.dart';
import 'package:artilier_demo/Service/auth_service.dart';
import 'package:artilier_demo/View/login_screen.dart';
import 'package:artilier_demo/user/upload_screen.dart';
import 'package:artilier_demo/user/notification_screen.dart';
import 'package:artilier_demo/user/profile_screen.dart';
import '../mock_data.dart';
import '../Service/photo_service.dart';
import 'package:artilier_demo/user/transaction_history.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artilier_demo/config.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final AuthService authService = AuthService();
  final PhotoService photoService = PhotoService();
  late Future<List<Map<String, dynamic>>> _photosFuture;
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;
  String _currentSort = 'newest';

  Future<List<Map<String, dynamic>>> _fetchPhotos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final idToken = await user.getIdToken();
      String url = '${ApiConfig.baseUrl}/photos.php?sort=$_currentSort';
      if (_selectedCategory != null) {
        url += '&category=$_selectedCategory';
      }

      final response = await http.get(
        Uri.parse(url),
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
                  'uploader': photo['uploader_email'], // Keep email for logic
                  'uploaderName': photo['uploader_name'] ?? photo['uploader_email'], // Display name
                  'uploaderUid': photo['uploader_uid'], // New UID field
                  'status': photo['status'],
                  'highestBidder': photo['highest_bidder'] ?? 'No one',
                  'highestBid': photo['highest_bid']?.toString() ?? '0',
                  'category': photo['category'] ?? 'Uncategorized',
                  'likeCount': photo['like_count']?.toString() ?? '0',
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching photos: $e');
    }
    return [];
  }

  Future<void> _loadCategories() async {
    final categories = await photoService.getCategories();
    setState(() {
      _categories = ['All', ...categories];
      _isLoadingCategories = false;
    });
  }

  Future<void> _testApiCall() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/me.php'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Response: ${response.body}')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openDetail(Map<String, dynamic> photo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(photo: photo.cast<String, String>()),
      ),
    );

    // Always refresh when returning from detail screen to update like counts
    if (mounted) {
      setState(() {
        _photosFuture = _fetchPhotos();
      });
    }
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
      _photosFuture = _fetchPhotos();
    });
  }

  Widget _buildSortButton(String title, String sortValue) {
    final isSelected = _currentSort == sortValue;
    return GestureDetector(
      onTap: () {
        if (_currentSort != sortValue) {
          setState(() {
            _currentSort = sortValue;
            _photosFuture = _fetchPhotos();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _photosFuture = _fetchPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.getCurrentUser();
    final currentEmail = currentUser?.email ?? 'anonymous';

    // Count notifications for current user
    final bidNotifications = MockData.approvedPhotos
        .where((photo) =>
            photo['uploader'] == currentEmail &&
            photo['highestBidder'] != 'No one' &&
            (photo['status'] ?? 'available') == 'available')
        .length;

    final paymentNotifications = MockData.paymentNotifications
        .where((notif) => notif['bidder'] == currentEmail)
        .length;

    final shippingNotifications = MockData.shippingNotifications
        .where((notif) => notif['seller'] == currentEmail)
        .length;

    final totalNotifications =
        bidNotifications + paymentNotifications + shippingNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/artilier.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              'Home',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.black, size: 28),
            onPressed: () {
               // Navigation to history (if available) or placeholder
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TransactionHistoryScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  );
                  setState(() {}); 
                },
              ),
              if (totalNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$totalNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildSortButton('Just Added', 'newest'),
                const SizedBox(width: 12),
                _buildSortButton('Popular Now', 'popular'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _photosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Theres no paint available',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final availablePhotos = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: availablePhotos.length,
                  itemBuilder: (context, index) {
                    final photo = availablePhotos[index];
                    return GestureDetector(
                      onTap: () => _openDetail(photo),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.memory(
                                      base64Decode(photo['image']!),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.favorite, size: 16, color: Colors.red), // Always red to indicate popularity metric? Or use border? Let's use red or black. Previous was border.
                                        // Let's stick to showing count.
                                        const SizedBox(width: 4),
                                        Text(
                                          photo['likeCount'] ?? '0',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photo['title'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    photo['uploader'] ?? photo['uploader_email'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
