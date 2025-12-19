import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artilier_demo/config.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;
  final String? _currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions.php'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((transaction) => {
                  'id': transaction['id'].toString(),
                  'buyer_email': transaction['buyer_email'],
                  'seller_email': transaction['seller_email'],
                  'photo_title': transaction['photo_title'],
                  'photo_image': transaction['photo_image'],
                  'amount': transaction['amount'].toString(),
                  'tracking_number': transaction['tracking_number'],
                  'courier': transaction['courier'],
                  'status': transaction['status'],
                  'created_at': transaction['created_at'],
                  'category': 'Art', // Default since not joined yet, or map from title/logic
                })
            .toList();
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }
    return [];
  }

  String _formatCurrency(String amount) {
    // Simple formatter, can use NumberFormat if needed
    return '\$$amount';
  }

  String _formatName(String email) {
    // Extract name from email (e.g. alfi.mtd@gmail.com -> Alfi mtd)
    try {
      final part = email.split('@')[0];
      // Replace dots/underscores with spaces and capitalize
      return part.replaceAll(RegExp(r'[._]'), ' ').split(' ').map((str) {
        if (str.isEmpty) return '';
        return str[0].toUpperCase() + str.substring(1);
      }).join(' ');
    } catch (_) {
      return email;
    }
  }

  String _formatDate(String dateStr) {
     // Expecting MySQL datetime or similar: 2025-12-15 10:00:00
     try {
       final date = DateTime.parse(dateStr);
       final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
       return '${months[date.month - 1]} ${date.day}, ${date.year}';
     } catch (_) {
       return dateStr;
     }
  }

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/artilier.png', 
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'History',
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
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              final title = t['photo_title'] ?? 'Artwork';
              final amount = t['amount'] ?? '0';
              final date = _formatDate(t['created_at'] ?? DateTime.now().toString());
              final trackingNumber = t['tracking_number'];
              final img = t['photo_image'];
              
              // Logic to determine role and display name
              final isBuyer = t['buyer_email'] == _currentUserEmail;
              // If isBuyer, show Seller Name. If isSeller, show Buyer Name.
              final otherEmail = isBuyer ? (t['seller_email'] ?? '?') : (t['buyer_email'] ?? '?');
              final displayName = _formatName(otherEmail); // Use as subtitle

              // Status logic
              // User said "completed... when tracking available".
              // So if tracking exists, show "Completed". Else "Processing" or logic.
              final status = (trackingNumber != null && trackingNumber.toString().isNotEmpty) 
                  ? 'Completed' 
                  : (t['status'] == 'sold' ? 'Processing' : t['status']);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9), // Light greyish background from screenshot
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
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: img != null
                            ? Image.memory(
                                base64Decode(img),
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Details Middle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date, // "Dec 15, 2025" style
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price & Status Right
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(amount),
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
                            color: Colors.grey[300], // Grey badge background
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status, // "Completed"
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        if (trackingNumber != null && trackingNumber.toString().isNotEmpty)
                          Padding(
                             padding: const EdgeInsets.only(top: 4),
                             child: Text(
                               'Trk: $trackingNumber',
                               style: const TextStyle(fontSize: 10, color: Colors.grey),
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
      ),
    );
  }
}
