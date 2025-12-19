import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:artilier_demo/user/photo_detail_screen.dart';
import 'package:artilier_demo/Service/photo_service.dart';
import 'package:artilier_demo/config.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class LikedPhotosScreen extends StatefulWidget {
  const LikedPhotosScreen({super.key});

  @override
  State<LikedPhotosScreen> createState() => _LikedPhotosScreenState();
}

class _LikedPhotosScreenState extends State<LikedPhotosScreen> {
  final PhotoService _photoService = PhotoService();
  late Future<List<Map<String, dynamic>>> _likedPhotosFuture;

  Future<List<Map<String, dynamic>>> _fetchLikedPhotos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final likedPhotoIds = await _photoService.getLikedPhotoIds();
      if (likedPhotoIds.isEmpty) return [];

      final idToken = await user.getIdToken(true);
      final List<Map<String, dynamic>> allPhotos = [];

      for (String photoId in likedPhotoIds) {
        try {
          // Fix: Fetch specific photo by ID to bypass status filtering (e.g. show sold items too)
          // and improve performance (don't fetch all photos).
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/photos.php?id=$photoId'),
            headers: {
              'Authorization': 'Bearer $idToken',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            // API returns a list containing the single photo
            if (data.isNotEmpty) {
               final photo = data.first;
               allPhotos.add({
                'id': photo['id'].toString(),
                'title': photo['title'],
                'image': photo['image_data'], // API returns base64
                'uploader': photo['uploader_email'],
                'status': photo['status'],
                'highestBidder': photo['highest_bidder'] ?? 'No one',
                'highestBid': photo['highest_bid']?.toString() ?? '0',
                'category': photo['category'] ?? 'Uncategorized',
              });
            }
          }
        } catch (e) {
          print('Error fetching photo $photoId: $e');
        }
      }

      return allPhotos;
    } catch (e) {
      print('Error fetching liked photos: $e');
      return [];
    }
  }

  Future<void> _openDetail(Map<String, dynamic> photo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(photo: photo.cast<String, String>()),
      ),
    );
    if (mounted) {
      setState(() {
        _likedPhotosFuture = _fetchLikedPhotos();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _likedPhotosFuture = _fetchLikedPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Favorites', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _likedPhotosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No liked photos yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start liking photos to see them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final likedPhotos = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _likedPhotosFuture = _fetchLikedPhotos();
              });
              await _likedPhotosFuture;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: likedPhotos.length,
              itemBuilder: (context, index) {
                final photo = likedPhotos[index];
                return GestureDetector(
                  onTap: () => _openDetail(photo),
                  child: Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Image.memory(
                                base64Decode(photo['image']!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photo['category'] ?? 'Uncategorized',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
