import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:artilier_demo/config.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}


class _BalanceScreenState extends State<BalanceScreen> {
  bool _isLoading = true;
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  String _debugInfo = "";

  @override
  void initState() {
    super.initState();
    _fetchBalanceData();
  }

  Future<void> _fetchBalanceData() async {
    final user = FirebaseAuth.instance.currentUser;
    
    // Safety check BEFORE try block, but also handle loading state
    if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
    }

    setState(() => _debugInfo = "User: ${user.email}\nUID: ${user.uid}\nFetching...");

    try {
      final idToken = await user.getIdToken();
      
      // Fetch Transactions (we know this works!)
      final transResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions.php'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (transResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(transResponse.body);
        _transactions = data.map((t) => t as Map<String, dynamic>).toList();
        
        // Calculate balance from sales (where you are the seller)
        double totalEarnings = 0.0;
        for (var t in _transactions) {
          if (t['seller_email'] == user.email) {
            totalEarnings += double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
          }
        }
        
        _balance = totalEarnings;
        print("Calculated balance from ${_transactions.length} transactions: $_balance");
      }

    } catch (e) {
      print("Error fetching balance: $e");
      setState(() => _debugInfo += "\nError: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Balance', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 40, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Withdraw Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Withdrawal feature coming soon!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Withdraw Funds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Transaction List
                  if (_transactions.isEmpty)
                     const Padding(
                       padding: EdgeInsets.only(top: 20),
                       child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)),
                     )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final t = _transactions[index];
                        final userEmail = FirebaseAuth.instance.currentUser?.email;
                        final isSale = t['seller_email'] == userEmail;
                        final amount = double.tryParse(t['amount'].toString()) ?? 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSale ? Colors.green.shade50 : Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSale ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isSale ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSale ? 'Sale: ${t['photo_title']}' : 'Purchase: ${t['photo_title']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t['created_at']?.toString().split(' ')[0] ?? '',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isSale ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSale ? Colors.green : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
