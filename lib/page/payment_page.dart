import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'payment_complete_page.dart';

class PaymentPage extends StatefulWidget {
  final String invoiceId;           // only the invoiceId is passed in

  const PaymentPage({super.key, required this.invoiceId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = '';

  Future<void> _confirmPayment() async {
    final query = await FirebaseFirestore.instance
        .collection('invoices')
        .where('invoiceId', isEqualTo: widget.invoiceId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invoice not found')));
      }
      return;
    }

    final docId = query.docs.first.id;
    await FirebaseFirestore.instance
        .collection('invoices')
        .doc(docId)
        .update({'paymentStatus': 'Paid'});
  }

  Future<void> _showConfirmDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFC107),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Proceed with Payment',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Do you want to confirm this payment method?',
                style: TextStyle(color: Colors.black87, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _confirmPayment();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentCompletePage(),
                          ),
                        );
                      }
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('invoiceId', isEqualTo: widget.invoiceId)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Invoice not found')),
          );
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final String bookingId     = data['bookingId'] ?? '';
        final String invoiceDate   = data['invoiceDate'] ?? '';
        final String serviceCenter = data['serviceCenter'] ?? '';
        final List items           = data['items'] ?? [];
        final num total            = data['total'] ?? 0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFC107),
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            title: const Text(
              'Payment',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _invoiceCard(widget.invoiceId, serviceCenter,
                  invoiceDate, bookingId, items, total),
              const SizedBox(height: 24),
              const Text(
                'Payment Method:',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _paymentOption('PayPal', 'assets/images/paypal.png'),
                  const SizedBox(width: 24),
                  _paymentOption('Touch n Go', 'assets/images/tng.png'),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _selectedMethod.isEmpty ? null : _showConfirmDialog,
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _invoiceCard(String invoiceId, String center, String date,
      String booking, List items, num total) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const Text(
                  'Invoice ID:',
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
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Service Center:', center),
                _detailRow('Date:', date),
                _detailRow('Booking ID:', booking),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Billing Breakdown:',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _billingTable(items, total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingTable(List items, num total) {
    return Table(
      border: TableBorder.all(color: Colors.black12, width: 0.5),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
      children: [
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFF8F8F8)),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Item',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Price',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        ),
        for (var item in items)
          TableRow(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(item['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('RM ${item['amount']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ]),
        TableRow(children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Total (RM):',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '$total',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _paymentOption(String name, String assetPath) {
    final bool selected = _selectedMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = name),
      child: Container(
        width: 120,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFC107) : Colors.black12,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(assetPath, height: 32),
        ),
      ),
    );
  }
}
