import 'package:flutter/material.dart';
import 'package:artilier_demo/Service/photo_service.dart';
import 'package:artilier_demo/user/category_feed_screen.dart';
import 'package:artilier_demo/user/transaction_history.dart';
import 'package:artilier_demo/user/notification_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final PhotoService _photoService = PhotoService();
  List<String> _categories = [];
  bool _isLoading = true;

  // Map categories to Unsplash Art keywords/URLs for demo purposes
  // In a real app, these would be assets or stored URLs
  final Map<String, String> _categoryImages = {
    'Modern Canvas': 'assets/modern_canvas.png',
    'Classic Painting': 'assets/classsics_painting.png',
    'Abstract': 'assets/abstract.png',
    'Portrait': 'assets/potraits.png',
    'Landscape': 'assets/landscape.png',
    'Pop Art': 'assets/pop_art.png',
  };

  final String _defaultImage = 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=600&q=80';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _photoService.getCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

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
            const Text(
              'Categories',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85, // Adjust for card shape
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final imageUrl = _categoryImages[category] ?? _defaultImage;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryFeedScreen(categoryName: category),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: category == 'Modern Canvas' 
                            ? Border.all(color: Colors.blueAccent, width: 2) // Emulate selection from screenshot
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), // slightly less to fit
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text(
                                category,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
