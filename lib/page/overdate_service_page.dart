import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'service_booking_details_page.dart';
import '../widgets/booking_calendar.dart';

class OverdateServicePage extends StatefulWidget {
  const OverdateServicePage({super.key});

  @override
  State<OverdateServicePage> createState() => _OverdateServicePageState();
}

class _OverdateServicePageState extends State<OverdateServicePage> {
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFC107),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Overdate Service',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? _buildNotLoggedIn()
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildNoOverdateServices();
                  }

                  // Filter overdue services
                  final overdueServices = _filterOverdueServices(snapshot.data!.docs);
                  
                  if (overdueServices.isEmpty) {
                    return _buildNoOverdateServices();
                  }

                  return _buildOverdateServicesList(overdueServices);
                },
              ),
            ),
    );
  }

  List<QueryDocumentSnapshot> _filterOverdueServices(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';
      
      // Check if it's a past date and not completed/cancelled
      if (status == 'completed' || status == 'cancelled') {
        return false;
      }
      
      final dateStr = data['date']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      
      DateTime? serviceDate;
      if (data['date'] is Timestamp) {
        serviceDate = (data['date'] as Timestamp).toDate();
      } else {
        serviceDate = DateTime.tryParse(dateStr);
      }
      
      if (serviceDate == null) return false;
      
      final serviceDateOnly = DateTime(serviceDate.year, serviceDate.month, serviceDate.day);
      return serviceDateOnly.isBefore(today);
    }).toList();
  }

  Widget _buildNotLoggedIn() {
    return Center(
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
            'Please login to view overdue services',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
      ),
    );
  }

  Widget _buildNoOverdateServices() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Overdue Services',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All your services are up to date',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdateServicesList(List<QueryDocumentSnapshot> docs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>;
          return _buildOverdateServiceCard(data, doc.id);
        },
      ),
    );
  }

  Widget _buildOverdateServiceCard(Map<String, dynamic> data, String bookingId) {
    final bookingIdDisplay = data['bookingId']?.toString() ?? bookingId;
    final serviceType = data['serviceType']?.toString() ?? 'Service';
    final date = _formatDate(data['date']);
    final location = data['location']?.toString() ?? data['workshopName']?.toString() ?? 'Service Location';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Booking ID and Overdate badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking ID: $bookingIdDisplay',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  'Overdate',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Service Details
          _buildDetailRow('Services Type', serviceType),
          const SizedBox(height: 8),
          _buildDetailRow('Date', date),
          const SizedBox(height: 8),
          _buildDetailRow('Enquiry Location', location),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              // View Details Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceBookingDetailsPage(bookingId: bookingId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Reschedule Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showRescheduleDialog(data, bookingId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reschedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> data, String bookingId) {
    final bookingIdDisplay = data['bookingId']?.toString() ?? bookingId;
    final brand = data['brand']?.toString() ?? 'Unknown';
    final model = data['model']?.toString() ?? 'Unknown';
    final plateNumber = data['plateNumber']?.toString() ?? 'N/A';
    final workshopName = data['workshopName']?.toString() ?? 'Workshop';
    final workshopAddress = data['workshopAddress']?.toString() ?? 'Address not available';
    final serviceType = data['serviceType']?.toString() ?? 'Service';
    
    DateTime? selectedDate;
    String? selectedTime;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Reschedule Service',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Booking ID
                      _buildRescheduleDetailRow('Booking ID:', bookingIdDisplay),
                      const SizedBox(height: 12),
                      
                      // Vehicle Details
                      const Text(
                        'Vehicle Details:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$brand $model',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildRescheduleDetailRow('Plate Number:', plateNumber),
                      
                      const SizedBox(height: 16),
                      
                      // Workshop & Booking Information
                      const Text(
                        'Workshop & Booking Information:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRescheduleDetailRow('Workshop Name:', workshopName),
                      const SizedBox(height: 8),
                      _buildRescheduleDetailRow('Workshop Address:', workshopAddress),
                      
                      const SizedBox(height: 16),
                      
                      // Services Info
                      const Text(
                        'Services Info',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRescheduleDetailRow('Services Type:', serviceType),
                      
                      const SizedBox(height: 20),
                      
                      // Date & Time Selection (Mon–Fri, fixed slots, max 2 per slot)
                      const Text(
                        'Choose Date & Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: BookingCalendar(
                          onSlotSelected: (date, time) {
                            setState(() {
                              selectedDate = date;
                              selectedTime = time;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedDate != null && selectedTime != null
                            ? 'Selected: ${DateFormat('EEEE, MMM d').format(selectedDate!)} at ${DateFormat('h:mm a').format(DateFormat('HH:mm').parse(selectedTime!))}'
                            : 'Select a weekday (Mon–Fri) and a time slot',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selectedDate == null || selectedTime == null
                                  ? null
                                  : () async {
                                      final ok = await _rescheduleService(
                                        bookingId,
                                        selectedDate!,
                                        selectedTime!,
                                      );
                                      if (ok && context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Confirm Reschedule',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildRescheduleDetailRow(String label, String value) {
    return Row(
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _rescheduleService(String bookingId, DateTime newDate, String newTime) async {
    try {
      // Enforce weekday
      if (newDate.weekday > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please choose a weekday (Mon–Fri).'),
            backgroundColor: Colors.red[600],
          ),
        );
        return false;
      }

      final DateTime dayStart = DateTime(newDate.year, newDate.month, newDate.day);
      final DateTime dayEnd = DateTime(newDate.year, newDate.month, newDate.day, 23, 59, 59, 999);

      // Check capacity for the selected slot (max 2)
      final QuerySnapshot existing = await FirebaseFirestore.instance
          .collection('bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dayEnd))
          .get();

      final int activeCount = existing.docs.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final status = (data['status']?.toString().toLowerCase() ?? '');
        final timeMatches = (data['time']?.toString() ?? '') == newTime;
        final isSameDoc = d.id == bookingId;
        return timeMatches && !isSameDoc && status != 'cancelled';
      }).length;

      if (activeCount >= 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Selected time slot is full. Please choose another.'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
        return false;
      }

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'date': Timestamp.fromDate(newDate),
        'time': newTime,
        'status': 'confirmed',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showRescheduleSuccessDialog(bookingId, newDate, newTime);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Failed to reschedule. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return false;
    }
  }

  void _showRescheduleSuccessDialog(String bookingId, DateTime date, String time) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Check icon circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.black,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for rescheduling\nfor the Service',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic date) {
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
}
