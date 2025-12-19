import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artilier_demo/config.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../Service/auth_service.dart';
import '../Service/photo_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    required this.photo,
  });

  final Map<String, String> photo;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final AuthService authService = AuthService();
  final PhotoService photoService = PhotoService();
  final _bidController = TextEditingController();
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoadingLike = true;

  Future<void> _placeBid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final bidAmount = _bidController.text;
    if (bidAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter bid amount')),
      );
      return;
    }

    final bidInt = int.tryParse(bidAmount);
    final currentHighest = int.tryParse(widget.photo['highestBid'] ?? '0') ?? 0;
    if (bidInt == null || bidInt <= currentHighest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid must be higher than current')),
      );
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/bids.php'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'photo_id': widget.photo['id'],
          'amount': bidAmount,
          'seller_email': widget.photo['uploader'],
          'user_name': user.displayName ?? user.email!.split('@')[0], 
        }),
      );

      if (response.statusCode == 200) {
        // Refresh details to get the new bid info
        await _refreshPhotoDetails();
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Bid placed successfully')),
           );
        }
      } else {
        throw Exception('Bid failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bid failed: $e')),
      );
    }
  }

  Future<void> _toggleLike() async {
    try {
      setState(() => _isLoadingLike = true);

      if (_isLiked) {
        await photoService.unlikePhoto(widget.photo['id']!);
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likeCount = (_likeCount > 0) ? _likeCount - 1 : 0;
          });
        }
      } else {
        await photoService.likePhoto(widget.photo['id']!);
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount = _likeCount + 1;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLike = false);
      }
    }
  }

  Future<void> _loadLikeStatus() async {
    try {
      final isLiked = await photoService.isPhotoLiked(widget.photo['id']!);
      final likeCount = await photoService.getLikeCount(widget.photo['id']!);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _likeCount = likeCount;
          _isLoadingLike = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLike = false);
      }
    }
  }

  Future<void> _refreshPhotoDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/photos.php?id=${widget.photo['id']}'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final updatedPhoto = data[0];
          if (mounted) {
            setState(() {
              widget.photo['highestBid'] = updatedPhoto['highest_bid']?.toString() ?? '0';
              widget.photo['highestBidder'] = updatedPhoto['highest_bidder'] ?? 'No one';
              widget.photo['status'] = updatedPhoto['status'] ?? 'available';
               // Update uploader info in case it changed
              widget.photo['uploader'] = updatedPhoto['uploader_email'] ?? ''; 
              widget.photo['uploaderUid'] = updatedPhoto['uploader_uid'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      print('Error refreshing photo details: $e');
    }
  }

  Future<void> _syncAndRefresh() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        await http.get(
          Uri.parse('${ApiConfig.baseUrl}/sync_profile.php'),
          headers: {'Authorization': 'Bearer $idToken'},
        );
      }
    } catch (e) {
      print("Sync error: $e");
    }
    await _refreshPhotoDetails();
  }

  Future<void> _deletePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artwork?'),
        content: const Text('Are you sure you want to delete this artwork? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final idToken = await user.getIdToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/photos.php?id=${widget.photo['id']}'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork deleted successfully')),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to signal deletion
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _acceptOffer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final idToken = await user.getIdToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/photos.php'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'photo_id': widget.photo['id'],
          'status': 'sold',
        }),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          widget.photo['status'] = 'sold';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted! Item marked as sold.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
    _syncAndRefresh();
  }

  String _formatCurrency(String amount) {
    return '\$$amount';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return DateFormat('MMM dd, yyyy').format(DateTime.now());
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date); // Dec 15, 2025
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final currentUser = authService.getCurrentUser();
    final currentEmail = currentUser?.email ?? 'anonymous';
    final currentUid = currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        actions: [
          if ((currentUid != null && photo['uploaderUid'] == currentUid) || 
              (photo['uploader'] == currentEmail))
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deletePhoto,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Container(
              height: 350, // Large height like in screenshot
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Rounded corners
                child: Image.memory(
                  base64Decode(photo['image']!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title and Like
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo['title'] ?? 'Artwork',
                        style: const TextStyle(
                          fontSize: 22,
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
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleLike,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.grey[100],
                    ),
                    child: _isLoadingLike
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                          size: 24,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Price and Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrency(photo['highestBid'] ?? '0'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _formatDate(photo['created_at'] ?? DateTime.now().toString()), // Use created_at or current date
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Bidding Section (Replaces Admin Controls)
            const Text(
              "Place a Bid",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _placeBid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Place Bid',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

             // Accept Offer Button (Restored Logic)
            if (photo['uploader'] == currentEmail &&
                photo['highestBidder'] != 'No one' &&
                (photo['status'] ?? 'available') == 'available') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _acceptOffer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                     shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Accept Offer'),
                ),
              ),
            ],

            // Delete Button for Owner
             if ((currentUid != null && photo['uploaderUid'] == currentUid) || 
                 (photo['uploader'] == currentEmail)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _deletePhoto,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete Artwork'),
                ),
              ),
            ],
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
