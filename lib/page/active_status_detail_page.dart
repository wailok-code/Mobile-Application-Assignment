import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActiveStatusDetailPage extends StatefulWidget {
  final String bookingId;

  const ActiveStatusDetailPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<ActiveStatusDetailPage> createState() => _ActiveStatusDetailPageState();
}

class _ActiveStatusDetailPageState extends State<ActiveStatusDetailPage> {
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

  String _getCarStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Widget _buildCarStatusSection(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Car Status:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Current Status row
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'Current Status',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getCarStatusText(status),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Status indicators based on actual status
        _buildStatusFlow(status),
        
        const SizedBox(height: 20),
        
        // Last Updated
        _buildDetailRow('Last Updated:', DateFormat('dd-MM-yyyy').format(DateTime.now())),
      ],
    );
  }

  Widget _buildStatusFlow(String status) {
    final statusLower = status.toLowerCase();
    
    // Linear progress flow showing all 5 statuses
    return Column(
      children: [
        // Progress indicators with connecting lines
        Row(
          children: [
            // Pending
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _shouldHighlight(statusLower, 0) ? const Color(0xFFFFC107) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: _shouldHighlight(statusLower, 0) ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pending',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: _shouldHighlight(statusLower, 0) ? const Color(0xFFFFC107) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Connecting line
            Expanded(
              child: Container(
                height: 2,
                color: _shouldHighlight(statusLower, 1) ? const Color(0xFFFFC107) : Colors.grey[300],
              ),
            ),
            
            // Confirmed
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _shouldHighlight(statusLower, 1) ? const Color(0xFFFFC107) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: _shouldHighlight(statusLower, 1) ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confirmed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: _shouldHighlight(statusLower, 1) ? const Color(0xFFFFC107) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Connecting line
            Expanded(
              child: Container(
                height: 2,
                color: _shouldHighlight(statusLower, 2) ? const Color(0xFFFFC107) : Colors.grey[300],
              ),
            ),
            
            // In Progress
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _shouldHighlight(statusLower, 2) ? const Color(0xFFFFC107) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.build,
                      color: _shouldHighlight(statusLower, 2) ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'In Progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: _shouldHighlight(statusLower, 2) ? const Color(0xFFFFC107) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Connecting line
            Expanded(
              child: Container(
                height: 2,
                color: _shouldHighlight(statusLower, 3) ? const Color(0xFFFFC107) : Colors.grey[300],
              ),
            ),
            
            // Completed
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _shouldHighlight(statusLower, 3) ? Colors.green : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: _shouldHighlight(statusLower, 3) ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                      color: _shouldHighlight(statusLower, 3) ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Special handling for cancelled status
            if (statusLower == 'cancelled') ...[
              // Connecting line to cancelled
              Expanded(
                child: CustomPaint(
                  painter: DottedLinePainter(color: Colors.red[400]!),
                ),
              ),
              
              // Cancelled
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cancelled',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  bool _shouldHighlight(String status, int step) {
    switch (status) {
      case 'pending':
        return step == 0; // Only Pending
      case 'confirmed':
        return step <= 1; // Pending + Confirmed
      case 'in_progress':
        return step <= 2; // Pending + Confirmed + In Progress
      case 'completed':
        return step <= 3; // Pending + Confirmed + In Progress + Completed
      case 'cancelled':
        return false; // Cancelled shows separately
      default:
        return false;
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

                // Car Status Section (NEW)
                _buildCarStatusSection(status),

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

// Custom painter for dotted line
class DottedLinePainter extends CustomPainter {
  final Color color;
  
  const DottedLinePainter({this.color = const Color(0xFFBDBDBD)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}