import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'invoice_detaiils.dart';
import 'payment_page.dart';
class BillingPage extends StatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  int _selectedIndex = 3;

  void _handleBottomNavigation(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/book');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/my-services');
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _handleBottomNavigation,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'My Services'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'E-Billings & Payment',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('invoices').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No invoices found'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return InvoiceCard(
                invoiceId: data['invoiceId'] ?? '',
                invoiceDate: data['invoiceDate'] ?? '',
                serviceCenter: data['serviceCenter'] ?? '',
                total: (data['total'] ?? 0).toString(),
                paymentStatus: data['paymentStatus'] ?? '',
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final String invoiceId;
  final String invoiceDate;
  final String serviceCenter;
  final String total;
  final String paymentStatus;

  const InvoiceCard({
    super.key,
    required this.invoiceId,
    required this.invoiceDate,
    required this.serviceCenter,
    required this.total,
    required this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPaid = paymentStatus.toLowerCase() == 'paid';
    final Color statusColor = isPaid ? Colors.green : Colors.red;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yellow header with invoice ID and status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Invoice ID: ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      invoiceId,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  paymentStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Service Center:', serviceCenter),
                _infoRow('Invoice Date:', invoiceDate),
                _infoRow('Total Amount:', 'RM $total', isLast: true),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        // Pass only invoiceId to details page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceDetailsPage(invoiceId: invoiceId),
                          ),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                    const SizedBox(width: 8),
                    if (!isPaid)
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentPage(invoiceId: invoiceId),
                            ),
                          );
                        },
                        child: const Text('Pay Now'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.black54),
        ),
        if (!isLast)
          const Divider(height: 16, thickness: 0.5, color: Colors.black12),
      ],
    );
  }
}
