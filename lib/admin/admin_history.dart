import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:artilier_demo/config.dart';
import 'package:intl/intl.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyPhotosFuture;

  Future<List<Map<String, dynamic>>> _fetchHistoryPhotos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final idToken = await user.getIdToken();
      // Fetch both approved and rejected photos
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/photos.php?mode=history'),
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
                  'status': photo['status'],
                  'highestBid': photo['highest_bid']?.toString() ?? '0',
                  'created_at': photo['created_at'],
                  // Map uploader name if available, else format email
                  'uploaderName': photo['uploader_name'] ?? photo['uploader_email'].split('@')[0],
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching history photos: $e');
    }
    return [];
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    _historyPhotosFuture = _fetchHistoryPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyPhotosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No history yet', style: TextStyle(color: Colors.grey)));
        }

        final photos = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            final status = photo['status'];
            final isApproved = status == 'approved';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // Light grey background
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(12), // Rounded Image
                    child: Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey,
                      child: Image.memory(
                        base64Decode(photo['image']!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Middle Section: Status, Title, Meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo['title'] ?? 'Artwork',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          photo['uploaderName'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          _formatDate(photo['created_at']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Right Section: Status Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                           color: Colors.grey[300], // Badge Background
                           borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isApproved ? 'Approved' : 'Rejected',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
