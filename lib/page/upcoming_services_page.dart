import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'service_booking_details_page.dart';
import 'invoice_details_page.dart';
import 'feedback_page.dart';

class UpcomingServicesPage extends StatefulWidget {
  final bool showPastServices;
  
  const UpcomingServicesPage({super.key, this.showPastServices = false});

  @override
  State<UpcomingServicesPage> createState() => _UpcomingServicesPageState();
}

class _UpcomingServicesPageState extends State<UpcomingServicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.index = widget.showPastServices ? 1 : 0;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.showPastServices ? 'Service History' : 'Upcoming Services',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFFC107),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFFC107),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              onTap: (index) {
                // Tab change handled by TabController
              },
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past Services'),
              ],
            ),
          ),

          // Service List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingServices(),
                _buildPastServices(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingServices() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
              'Please login to view your services',
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error in upcoming services: ${snapshot.error}');
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('No bookings found for user: ${user.uid}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming services',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book a service to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Filter for upcoming services (today and future dates, and not cancelled/completed)
        final now = DateTime.now();
        final currentDate = DateTime(now.year, now.month, now.day);
        
        final upcomingBookings = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
          final serviceDate = DateTime(date.year, date.month, date.day);
          final status = data['status']?.toString().toLowerCase() ?? '';
          
          // Include services that are today or in the future, and not cancelled or completed
          return serviceDate.isAfter(currentDate.subtract(const Duration(days: 1))) && 
                 status != 'cancelled' && 
                 status != 'completed';
        }).toList();

        debugPrint('Found ${upcomingBookings.length} upcoming bookings');

        if (upcomingBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming services',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book a service to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Sort upcoming bookings by date (earliest first)
        upcomingBookings.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = aData['date'] is Timestamp
              ? (aData['date'] as Timestamp).toDate()
              : DateTime.tryParse(aData['date']?.toString() ?? '') ?? DateTime.now();
          final bDate = bData['date'] is Timestamp
              ? (bData['date'] as Timestamp).toDate()
              : DateTime.tryParse(bData['date']?.toString() ?? '') ?? DateTime.now();
          return aDate.compareTo(bDate);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingBookings.length,
          itemBuilder: (context, index) {
            final doc = upcomingBookings[index];
            final booking = doc.data() as Map<String, dynamic>;
            final bookingId = doc.id;
        return _buildServiceListCard(booking, bookingId, isUpcoming: true);
          },
        );
      },
    );
  }

  Widget _buildPastServices() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
              'Please login to view your service history',
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

// past services 
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error in past services: ${snapshot.error}');
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          debugPrint('No bookings found for user: ${user.uid}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No past services',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your service history will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Filter for past services (completed or cancelled services that are in the past)
        final now = DateTime.now();
        final currentDate = DateTime(now.year, now.month, now.day);
        
        final pastBookings = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final date = data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
          final serviceDate = DateTime(date.year, date.month, date.day);
          final status = data['status']?.toString().toLowerCase() ?? '';
          
          // Include services that are completed, cancelled, or in the past
          return status == 'completed' || 
                 status == 'cancelled' || 
                 serviceDate.isBefore(currentDate);
        }).toList();

        debugPrint('Found ${pastBookings.length} past bookings');

        if (pastBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No past services',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your service history will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Sort past bookings by date (most recent first)
        pastBookings.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDate = aData['date'] is Timestamp
              ? (aData['date'] as Timestamp).toDate()
              : DateTime.tryParse(aData['date']?.toString() ?? '') ?? DateTime.now();
          final bDate = bData['date'] is Timestamp
              ? (bData['date'] as Timestamp).toDate()
              : DateTime.tryParse(bData['date']?.toString() ?? '') ?? DateTime.now();
          return bDate.compareTo(aDate); // Descending order (most recent first)
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pastBookings.length,
          itemBuilder: (context, index) {
            final doc = pastBookings[index];
            final booking = doc.data() as Map<String, dynamic>;
            final bookingId = doc.id;
        return _buildServiceListCard(booking, bookingId, isUpcoming: false);
          },
        );
      },
    );
  }

  Widget _buildServiceListCard(Map<String, dynamic> booking, String bookingId, {required bool isUpcoming}) {
    // Debug: Print all available fields
    debugPrint('=== Booking Data Debug ===');
    debugPrint('Booking ID: $bookingId');
    debugPrint('Available fields: ${booking.keys.toList()}');
    booking.forEach((key, value) {
      debugPrint('$key: $value (${value.runtimeType})');
    });
    debugPrint('========================');
    
    final date = booking['date'] is DateTime 
        ? booking['date'] as DateTime 
        : booking['date'] is Timestamp
        ? (booking['date'] as Timestamp).toDate()
        : DateTime.tryParse(booking['date']?.toString() ?? '') ?? DateTime.now();
    final serviceType = booking['serviceType'] as String? ?? 'Unknown Service';
    final location = booking['location'] as String? ?? 'Unknown Location';
    final status = booking['status'] as String? ?? 'unknown';
    final bookingIdDisplay = booking['bookingId'] as String? ?? 'N/A';
    final time = booking['time'] as String? ?? 'Not specified';
    final plateNumber = booking['plateNumber'] as String? ?? 'N/A';
    final brand = booking['brand'] as String? ?? '';
    final model = booking['model'] as String? ?? '';
    final mobileNumber = booking['mobileNumber'] as String? ?? 'N/A';
    final notes = booking['notes'] as String? ?? '';
    
    // Build vehicle display string
    String vehicleInfo = plateNumber;
    if (brand.isNotEmpty && model.isNotEmpty) {
      vehicleInfo = '$plateNumber ($brand $model)';
    } else if (brand.isNotEmpty) {
      vehicleInfo = '$plateNumber ($brand)';
    } else if (model.isNotEmpty) {
      vehicleInfo = '$plateNumber ($model)';
    }
    
    // Debug vehicle info
    debugPrint('Vehicle Info: $vehicleInfo (plate: $plateNumber, brand: $brand, model: $model)');
    
    // Calculate days until service
    final now = DateTime.now();
    final serviceDate = DateTime(date.year, date.month, date.day);
    final currentDate = DateTime(now.year, now.month, now.day);
    final daysUntilService = serviceDate.difference(currentDate).inDays;
    
    String daysInfo;
    Color daysColor;
    if (daysUntilService == 0) {
      daysInfo = 'Today';
      daysColor = Colors.red[600]!;
    } else if (daysUntilService == 1) {
      daysInfo = 'Tomorrow';
      daysColor = Colors.orange[600]!;
    } else if (daysUntilService <= 7) {
      daysInfo = 'In $daysUntilService days';
      daysColor = Colors.orange[600]!;
    } else {
      daysInfo = 'In $daysUntilService days';
      daysColor = Colors.grey[600]!;
    }

    // Determine status color and text
    Color statusColor;
    String statusText;

    if (isUpcoming) {
      switch (status) {
        case 'pending':
          statusColor = Colors.orange[600]!;
          statusText = 'PENDING';
          break;
        case 'confirmed':
          statusColor = Colors.green[600]!;
          statusText = 'UPCOMING';
          break;
        case 'in_progress':
          statusColor = const Color(0xFFFFC107);
          statusText = 'IN PROGRESS';
          break;
        case 'cancelled':
          statusColor = Colors.red[600]!;
          statusText = 'CANCELLED';
          break;
        default:
          statusColor = Colors.blue[600]!;
          statusText = 'UPCOMING';
      }
    } else {
      switch (status) {
        case 'completed':
        statusColor = Colors.green[600]!;
        statusText = 'COMPLETED';
          break;
        case 'cancelled':
          statusColor = Colors.red[600]!;
          statusText = 'CANCELLED';
          break;
        default:
        statusColor = Colors.grey[600]!;
        statusText = status.toUpperCase();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Service Type and Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking ID and Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking ID: $bookingIdDisplay',
                  style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                            fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
                  const SizedBox(height: 8),
                  // Service Type Highlight
                  Text(
                    serviceType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Quick Date and Time Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                Text(
                            DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(
                              fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Days until service - only show for upcoming services
                      if (isUpcoming) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: daysColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: daysColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                size: 12,
                                color: daysColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daysInfo,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: daysColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Vehicle Information Section
            _buildInfoRow(
              Icons.directions_car_outlined,
              'Vehicle',
              vehicleInfo,
            ),
            
            const SizedBox(height: 12),
            
            // Location and Contact Section
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.location_on_outlined,
                    'Workshop',
                    location,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoRow(
                    Icons.phone_outlined,
                    'Contact',
                    mobileNumber,
                  ),
                ),
              ],
            ),
            
            // Notes Section (if available)
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.note_outlined,
                'Notes',
                notes,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            if (isUpcoming) ...[
              // Upcoming Services Buttons
              SizedBox(
                width: double.infinity,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Past Services Buttons
              Column(
                children: [
                  // First Row: View Details and View Invoice
                  Row(
                    children: [
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvoiceDetailsPage(bookingId: bookingId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Invoice',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 8),
                  // Second Row: Rate Service or View Rate
                  _buildRatingButton(bookingId),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFFFFC107),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                label,
                  style: TextStyle(
                  fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 2),
                Text(
                value,
                  style: const TextStyle(
                  fontSize: 14,
                    fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  ),
                ),
              ],
            ),
        ),
      ],
    );
  }

  Widget _buildRatingButton(String bookingId) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedbacks')
          .where('userId', isEqualTo: user.uid)
          .where('bookingId', isEqualTo: bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildRateServiceButton(bookingId);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
              ),
              icon: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              label: const Text(
                'Loading...',
                  style: TextStyle(
                    fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        // Check if user has already rated this service
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // User has already rated - show View Rate button
          final feedbackDoc = snapshot.data!.docs.first;
          final feedbackData = feedbackDoc.data() as Map<String, dynamic>;
          
          return _buildViewRateButton(feedbackData);
        } else {
          // User hasn't rated yet - show Rate Service button
          return _buildRateServiceButton(bookingId);
        }
      },
    );
  }

  Widget _buildRateServiceButton(String bookingId) {
    return SizedBox(
      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FeedbackPage(bookingId: bookingId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text(
          'Rate Service',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildViewRateButton(Map<String, dynamic> feedbackData) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showViewRatingDialog(feedbackData);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(Icons.visibility, size: 18),
        label: const Text(
          'View Rate',
            style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            ),
          ),
      ),
    );
  }

  void _showViewRatingDialog(Map<String, dynamic> feedbackData) {
    final rating = feedbackData['rating'] ?? 0;
    final comment = feedbackData['comment'] ?? '';
    final timestamp = feedbackData['timestamp'] as Timestamp?;
    final dateStr = timestamp != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate())
        : 'Unknown date';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
            padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                        color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.star,
                        color: Colors.blue[600],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your Rating',
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
                    
                    // Rating Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                        rating > index ? Icons.star : Icons.star_border,
                        size: 32,
                        color: rating > index ? Colors.amber[600] : Colors.grey[400],
                          ),
                        );
                      }),
                    ),
                const SizedBox(height: 8),
                
              Text(
                  '$rating out of 5 stars',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Comment
                if (comment.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Comment:',
                  style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
                  ),
                  const SizedBox(height: 8),
              Container(
                    width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                      color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Date
              Text(
                  'Submitted on $dateStr',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                      'Close',
                style: TextStyle(
                        fontSize: 14,
                  fontWeight: FontWeight.w600,
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

}
