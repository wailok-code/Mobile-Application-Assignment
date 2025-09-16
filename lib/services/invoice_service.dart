import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class InvoiceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Automatically creates an invoice when a booking is completed
  static Future<void> createInvoiceForCompletedBooking(String bookingId, Map<String, dynamic> bookingData) async {
    try {
      // Check if invoice already exists for this booking
      final existingInvoice = await _firestore
          .collection('invoices')
          .where('bookingId', isEqualTo: bookingId)
          .get();
      
      if (existingInvoice.docs.isNotEmpty) {
        debugPrint('Invoice already exists for booking $bookingId');
        return;
      }
      
      // Generate invoice data from booking
      final invoiceData = await _generateInvoiceData(bookingId, bookingData);
      
      // Create invoice document
      await _firestore.collection('invoices').add(invoiceData);
      
      debugPrint('Invoice created successfully for booking $bookingId');
    } catch (e) {
      debugPrint('Error creating invoice for booking $bookingId: $e');
      rethrow;
    }
  }
  
  /// Generates invoice data structure from booking data
  static Future<Map<String, dynamic>> _generateInvoiceData(String bookingId, Map<String, dynamic> bookingData) async {
    // Generate unique invoice ID
    final invoiceId = await _generateInvoiceId();
    
    // Extract booking details
    final serviceType = bookingData['serviceType']?.toString() ?? 'Service';
    final plateNumber = bookingData['plateNumber']?.toString() ?? '';
    final brand = bookingData['brand']?.toString() ?? '';
    final model = bookingData['model']?.toString() ?? '';
    final serviceCenter = bookingData['location']?.toString() ?? 
                        bookingData['workshopName']?.toString() ?? 'CarCare+';
    
    // Build vehicle info
    String vehicleInfo = plateNumber;
    if (brand.isNotEmpty && model.isNotEmpty) {
      vehicleInfo = '$plateNumber ($brand $model)';
    } else if (brand.isNotEmpty) {
      vehicleInfo = '$plateNumber ($brand)';
    }
    
    // Generate itemized services based on service type
    final items = _generateServiceItems(serviceType, vehicleInfo);
    
    // Calculate totals
    final subtotal = items.fold<double>(0, (total, item) => total + item['amount']);
    const sstRate = 0.06; // 6% SST
    final sst = subtotal * sstRate;
    final total = subtotal + sst;
    
    // Format invoice date
    final invoiceDate = _formatInvoiceDate(bookingData['date']);
    
    return {
      'bookingId': bookingId,
      'invoiceId': invoiceId,
      'invoiceDate': invoiceDate,
      'serviceCenter': serviceCenter,
      'items': items,
      'subtotal': subtotal,
      'sst': sst,
      'total': total,
      'paymentStatus': 'Unpaid',
      'createdAt': FieldValue.serverTimestamp(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    };
  }
  
  /// Generates service items based on service type
  static List<Map<String, dynamic>> _generateServiceItems(String serviceType, String vehicleInfo) {
    final items = <Map<String, dynamic>>[];
    final serviceTypeLower = serviceType.toLowerCase();
    
    // Base inspection fee
    items.add({
      'name': 'Inspection Fee',
      'amount': 150.0,
    });
    
    // Service-specific items
    if (serviceTypeLower.contains('oil change') || serviceTypeLower.contains('oil')) {
      items.add({
        'name': 'Engine Oil  ',
        'amount': 85.0,
      });
      if (serviceTypeLower.contains('gear') || serviceTypeLower.contains('transmission')) {
        items.add({
          'name': 'Gear Box Oil',
          'amount': 65.0,
        });
      }
    } else if (serviceTypeLower.contains('brake')) {
      items.add({
        'name': 'Brake Service',
        'amount': 200.0,
      });
      items.add({
        'name': 'Brake Fluid',
        'amount': 45.0,
      });
    } else if (serviceTypeLower.contains('tire') || serviceTypeLower.contains('tyre')) {
      items.add({
        'name': 'Tire Inspection & Service',
        'amount': 180.0,
      });
      items.add({
        'name': 'Wheel Alignment',
        'amount': 120.0,
      });
    } else if (serviceTypeLower.contains('engine')) {
      items.add({
        'name': 'Engine Diagnostic',
        'amount': 250.0,
      });
      items.add({
        'name': 'Engine Service',
        'amount': 350.0,
      });
    } else if (serviceTypeLower.contains('transmission')) {
      items.add({
        'name': 'Transmission Service',
        'amount': 300.0,
      });
      items.add({
        'name': 'Transmission Fluid',
        'amount': 80.0,
      });
    } else if (serviceTypeLower.contains('maintenance') || serviceTypeLower.contains('service')) {
      // General maintenance
      items.add({
        'name': 'General Maintenance',
        'amount': 120.0,
      });
      items.add({
        'name': 'Filter Replacement',
        'amount': 60.0,
      });
    } else {
      // Default service items
      items.add({
        'name': 'Service Fee',
        'amount': 100.0,
      });
    }
    
    return items;
  }
  
  /// Generates unique invoice ID in format I0001, I0002, etc.
  static Future<String> _generateInvoiceId() async {
    try {
      // Get the latest invoice to determine the next number
      final latestInvoices = await _firestore
          .collection('invoices')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      int nextNumber = 1;
      
      if (latestInvoices.docs.isNotEmpty) {
        final latestInvoiceId = latestInvoices.docs.first.data()['invoiceId'] as String?;
        if (latestInvoiceId != null && latestInvoiceId.startsWith('I')) {
          // Extract number from I0001 format
          final numberStr = latestInvoiceId.substring(1);
          final currentNumber = int.tryParse(numberStr) ?? 0;
          nextNumber = currentNumber + 1;
        }
      }
      
      // Format as I0001, I0002, etc.
      return 'I${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('Error generating invoice ID: $e');
      // Fallback to timestamp-based ID if there's an error
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fallbackNumber = timestamp % 10000;
      return 'I${fallbackNumber.toString().padLeft(4, '0')}';
    }
  }
  
  /// Formats invoice date from booking date
  static String _formatInvoiceDate(dynamic date) {
    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
      } else if (date is String) {
        final parsedDate = DateTime.tryParse(date);
        if (parsedDate != null) {
          return '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}';
        }
      }
    } catch (e) {
      debugPrint('Error formatting invoice date: $e');
    }
    
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
  }
  
  /// Monitors booking status changes and creates invoices for completed bookings
  static void startInvoiceMonitoring() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final bookingData = change.doc.data() as Map<String, dynamic>;
          final bookingId = change.doc.id;
          final status = bookingData['status']?.toString().toLowerCase();
          
          // Create invoice if status changed to completed
          if (status == 'completed') {
            createInvoiceForCompletedBooking(bookingId, bookingData);
          }
        }
      }
    });
  }
  
  /// Checks all existing completed bookings and creates invoices if they don't exist
  static Future<void> processExistingCompletedBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final completedBookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();
      
      for (final doc in completedBookings.docs) {
        final bookingData = doc.data();
        final bookingId = doc.id;
        
        // Check if invoice already exists
        final existingInvoice = await _firestore
            .collection('invoices')
            .where('bookingId', isEqualTo: bookingId)
            .get();
        
        if (existingInvoice.docs.isEmpty) {
          await createInvoiceForCompletedBooking(bookingId, bookingData);
        }
      }
    } catch (e) {
      debugPrint('Error processing existing completed bookings: $e');
    }
  }
  
  /// Utility function to manually trigger invoice creation for a specific booking
  /// This can be used for testing or manual invoice generation
  static Future<void> createInvoiceForBooking(String bookingId) async {
    try {
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (bookingDoc.exists) {
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        await createInvoiceForCompletedBooking(bookingId, bookingData);
        debugPrint('Manual invoice creation successful for booking $bookingId');
      } else {
        debugPrint('Booking not found: $bookingId');
      }
    } catch (e) {
      debugPrint('Error creating manual invoice for booking $bookingId: $e');
    }
  }
}
