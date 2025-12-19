import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artilier_demo/config.dart';
import 'package:artilier_demo/user/photo_detail_screen.dart';

class MyArtworksScreen extends StatefulWidget {
  const MyArtworksScreen({super.key});

  @override
  State<MyArtworksScreen> createState() => _MyArtworksScreenState();
}

class _MyArtworksScreenState extends State<MyArtworksScreen> {
  late Future<List<Map<String, dynamic>>> _photosFuture;

  @override
  void initState() {
    super.initState();
    _photosFuture = _fetchMyArtworks();
  }

  Future<List<Map<String, dynamic>>> _fetchMyArtworks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final idToken = await user.getIdToken();
      // Fetch my artworks using mode=mine (returns pending + approved)
      final url = '${ApiConfig.baseUrl}/photos.php?mode=mine&sort=newest';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final myEmail = user.email;

        return data
            .map((photo) => {
                  'id': photo['id'].toString(),
                  'title': photo['title'],
                  'image': photo['image_data'],
                  'uploader': photo['uploader_email'],
                  'uploaderName': photo['uploader_name'] ?? photo['uploader_email'],
                  'uploaderUid': photo['uploader_uid'],
                  'status': photo['status'],
                  'highestBidder': photo['highest_bidder'] ?? 'No one',
                  'highestBid': photo['highest_bid']?.toString() ?? '0',
                  'category': photo['category'] ?? 'Uncategorized',
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching my artworks: $e');
    }
    return [];
  }

  Future<void> _openDetail(Map<String, dynamic> photo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(photo: photo.cast<String, String>()),
      ),
    );

    if (result == true) {
      // Refresh list if photo was deleted
      setState(() {
        _photosFuture = _fetchMyArtworks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Artworks'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("You haven't posted any artworks yet."));
          }

          final photos = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
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
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.memory(
                            base64Decode(photo['image']!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
    );
  }
}
