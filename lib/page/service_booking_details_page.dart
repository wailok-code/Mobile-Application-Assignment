import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ServiceBookingDetailsPage extends StatefulWidget {
  final String bookingId;

  const ServiceBookingDetailsPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<ServiceBookingDetailsPage> createState() => _ServiceBookingDetailsPageState();
}

class _ServiceBookingDetailsPageState extends State<ServiceBookingDetailsPage> {



  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Booking Pending';
      case 'confirmed':
        return 'Booking Confirmed';
      case 'in_progress':
        return 'Service In Progress';
      case 'completed':
        return 'Service Completed';
      case 'cancelled':
        return 'Booking Cancelled';
      default:
        return 'Status Unknown';
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
          'Service Details',
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
                    'Please login to view booking details',
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
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Error in service details: ${snapshot.error}');
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

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
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

                final data = snapshot.data!.data() as Map<String, dynamic>;
                
                // Verify this booking belongs to the current user
                if (data['userId'] != user.uid) {
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
                          'You don\'t have permission to view this booking',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Parse the data with proper fallbacks
                final serviceDate = data['date'] is Timestamp
                    ? (data['date'] as Timestamp).toDate()
                    : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
                final status = data['status']?.toString() ?? 'unknown';
                final bookingIdDisplay = data['bookingId']?.toString() ?? widget.bookingId;
                
                // Build vehicle info
                final brand = data['brand']?.toString() ?? '';
                final model = data['model']?.toString() ?? '';
                String vehicleDisplay = '';
                if (brand.isNotEmpty && model.isNotEmpty) {
                  vehicleDisplay = '$brand $model';
                } else if (brand.isNotEmpty) {
                  vehicleDisplay = brand;
                } else if (model.isNotEmpty) {
                  vehicleDisplay = model;
                } else {
                  vehicleDisplay = 'Vehicle information not available';
                }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      // Booking ID Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                          'Booking ID: $bookingIdDisplay',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                      // Vehicle Details
                _buildSection(
                  'Vehicle Details:',
                  [
                          _buildDetailRow('Vehicle:', vehicleDisplay),
                    const SizedBox(height: 8),
                          _buildDetailRow('Plate Number:', data['plateNumber']?.toString() ?? 'Not provided'),
                  ],
                ),
                
                      // Service Information
                _buildSection(
                        'Service Information:',
                  [
                          _buildDetailRow('Service Type:', data['serviceType']?.toString() ?? 'Not specified'),
                          _buildDetailRow('Date:', DateFormat('dd MMM yyyy').format(serviceDate)),
                          _buildDetailRow('Time:', data['time']?.toString() ?? 'Not specified'),
                  ],
                ),
                
                      // Workshop Details
                _buildSection(
                        'Workshop Information:',
                        [
                          _buildDetailRow('Workshop:', data['location']?.toString() ?? 'Not specified'),
                          if (data['workshopAddress']?.toString().isNotEmpty ?? false) ...[
                            _buildDetailRow('Address:', data['workshopAddress'].toString()),
                    ],
                  ],
                ),

                      // Contact Information
                  _buildSection(
                        'Contact Information:',
                    [
                          _buildDetailRow('Mobile Number:', data['mobileNumber']?.toString() ?? 'Not provided'),
                    ],
                  ),

                      // Status Information
                  _buildSection(
                        'Status Information:',
                        [
                          _buildDetailRow('Current Status:', _getStatusDisplayText(status)),
                          if (data['createdAt'] != null) ...[
                            _buildDetailRow('Booking Created:', 
                              DateFormat('dd MMM yyyy, HH:mm').format(
                                data['createdAt'] is Timestamp
                                    ? (data['createdAt'] as Timestamp).toDate()
                                    : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
                              )
                            ),
                          ],
                          if (data['cancelledAt'] != null && status.toLowerCase() == 'cancelled') ...[
                            _buildDetailRow('Cancelled On:', 
                              DateFormat('dd MMM yyyy, HH:mm').format(
                                data['cancelledAt'] is Timestamp
                                    ? (data['cancelledAt'] as Timestamp).toDate()
                                    : DateTime.tryParse(data['cancelledAt'].toString()) ?? DateTime.now()
                              )
                            ),
                          ],
                        ],
                      ),

                      // Notes (if available)
                      if (data['notes']?.toString().isNotEmpty ?? false) ...[
                        _buildSection(
                          'Notes:',
                          [
                            Text(
                              data['notes'].toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            )
                          ],
                        ),
                      ],
                      
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}