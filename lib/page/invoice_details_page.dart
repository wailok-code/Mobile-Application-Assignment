import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class InvoiceDetailsPage extends StatefulWidget {
  final String bookingId;

  const InvoiceDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  
  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String amount, {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFFFFC107) : Colors.black87,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFFFFC107) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _processInvoiceData(Map<String, dynamic> invoiceData, Map<String, dynamic> bookingData) {
    // Process and format Firebase invoice data
    return {
      'invoiceId': invoiceData['invoiceId']?.toString() ?? 'N/A',
      'serviceCenter': invoiceData['serviceCenter']?.toString() ?? 
                     bookingData['location']?.toString() ?? 'CarCare+',
      'date': _formatInvoiceDate(invoiceData['invoiceDate'] ?? invoiceData['date']),
      'bookingId': invoiceData['bookingId']?.toString() ?? 
                   bookingData['bookingId']?.toString() ?? widget.bookingId,
      'carDetails': _buildCarDetails(bookingData),
      'items': invoiceData['items'] ?? [],
      'subtotal': _parseAmount(invoiceData['subtotal']),
      'sst': _parseAmount(invoiceData['sst'] ?? invoiceData['tax']),
      'total': _parseAmount(invoiceData['total'] ?? invoiceData['totalAmount']),
      'paymentStatus': invoiceData['paymentStatus']?.toString() ?? 'Paid',
      'paymentMethod': invoiceData['paymentMethod']?.toString() ?? 'Cash',
    };
  }

  String _formatInvoiceDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('dd-MM-yyyy').format(date.toDate());
    } else if (date is String) {
      final parsedDate = DateTime.tryParse(date);
      if (parsedDate != null) {
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      }
      return date;
    }
    return DateFormat('dd-MM-yyyy').format(DateTime.now());
  }

  double _parseAmount(dynamic amount) {
    if (amount is num) {
      return amount.toDouble();
    } else if (amount is String) {
      // Remove 'RM' and other non-numeric characters
      final cleanAmount = amount.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanAmount) ?? 0.0;
    }
    return 0.0;
  }

  String _buildCarDetails(Map<String, dynamic> bookingData) {
    final brand = bookingData['brand']?.toString() ?? '';
    final model = bookingData['model']?.toString() ?? '';
    final plateNumber = bookingData['plateNumber']?.toString() ?? '';
    
    if (brand.isNotEmpty && model.isNotEmpty && plateNumber.isNotEmpty) {
      return '$brand $model, $plateNumber';
    } else if (plateNumber.isNotEmpty) {
      return plateNumber;
    } else {
      return 'Vehicle information not available';
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green[100]!;
      case 'pending':
        return Colors.orange[100]!;
      case 'failed':
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getPaymentStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green[300]!;
      case 'pending':
        return Colors.orange[300]!;
      case 'failed':
      case 'cancelled':
        return Colors.red[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Color _getPaymentStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green[700]!;
      case 'pending':
        return Colors.orange[700]!;
      case 'failed':
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Invoice Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please login to view invoice details',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(widget.bookingId)
                  .snapshots(),
              builder: (context, bookingSnapshot) {
                if (bookingSnapshot.hasError) {
                  debugPrint('Error loading booking: ${bookingSnapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load booking details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                    ),
                  );
                }

                if (!bookingSnapshot.hasData || !bookingSnapshot.data!.exists) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Booking not found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The booking you\'re looking for doesn\'t exist',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bookingData = bookingSnapshot.data!.data() as Map<String, dynamic>;
                
                // Verify this booking belongs to the current user
                if (bookingData['userId'] != user.uid) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Access Denied',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You don\'t have permission to view this invoice',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Check if this is a completed service (has invoice)
                final status = bookingData['status']?.toString().toLowerCase() ?? '';
                if (status != 'completed') {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pending_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Invoice Not Available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invoice will be available after service completion',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Now get the invoice data from Firebase
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('invoices')
                      .doc(widget.bookingId)
                      .snapshots(),
                  builder: (context, invoiceSnapshot) {
                    if (invoiceSnapshot.hasError) {
                      debugPrint('Error loading invoice: ${invoiceSnapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Something went wrong',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Unable to load invoice details',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (invoiceSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                        ),
                      );
                    }
  
                    if (!invoiceSnapshot.hasData || !invoiceSnapshot.data!.exists) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Invoice Not Found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No invoice available for this booking',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final invoiceData = invoiceSnapshot.data!.data() as Map<String, dynamic>;
                    final processedData = _processInvoiceData(invoiceData, bookingData);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Invoice ID Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Invoice ID:   ${processedData['invoiceId']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Basic Information
                          _buildDetailRow('Service Center:', processedData['serviceCenter']),
                          _buildDetailRow('Date:', processedData['date']),
                          _buildDetailRow('Booking ID:', processedData['bookingId']),
                          
                          const SizedBox(height: 20),
                          
                          // Car Details Section
                          const Text(
                            'Car Details:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              processedData['carDetails'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Billing Breakdown Section
                          const Text(
                            'Billing Breakdown:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                // Header Row
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Item',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Price',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(thickness: 1),
                                
                                // Display invoice items from Firebase
                                ...processedData['items'].map<Widget>((item) {
                                  return _buildInvoiceRow(
                                    item['name']?.toString() ?? 'Service Item',
                                    'RM ${_parseAmount(item['amount']).toStringAsFixed(2)}',
                                  );
                                }).toList(),
                                
                                // If no items in Firebase, show default items
                                if (processedData['items'].isEmpty) ...[
                                  _buildInvoiceRow('Service Charge', 'RM ${processedData['subtotal'].toStringAsFixed(2)}'),
                                  if (processedData['sst'] > 0)
                                    _buildInvoiceRow('SST (6%)', 'RM ${processedData['sst'].toStringAsFixed(2)}'),
                                ],
                                
                                const SizedBox(height: 8),
                                const Divider(thickness: 1),
                                
                                _buildInvoiceRow('Total (RM):', 'RM ${processedData['total'].toStringAsFixed(0)}', isBold: true, isTotal: true),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Payment Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payment Status:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getPaymentStatusColor(processedData['paymentStatus']),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _getPaymentStatusBorderColor(processedData['paymentStatus'])),
                                ),
                                child: Text(
                                  processedData['paymentStatus'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _getPaymentStatusTextColor(processedData['paymentStatus']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Download Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.download, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Invoice ${processedData['invoiceId']} downloaded'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.download, size: 20),
                              label: const Text(
                                'Download Invoice',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
