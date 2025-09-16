import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'active_status_detail_page.dart';

class ActiveStatusSelectorPage extends StatefulWidget {
  const ActiveStatusSelectorPage({super.key});

  @override
  State<ActiveStatusSelectorPage> createState() => _ActiveStatusSelectorPageState();
}

class _ActiveStatusSelectorPageState extends State<ActiveStatusSelectorPage> {
  String _selectedFilter = 'All'; // All, Pending, Confirmed, In Progress, Cancelled

  @override
  Widget build(BuildContext context) {
    // Options were previously used to navigate; with dropdown filtering they are unused.

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Select Active Status',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Dropdown filter at top
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Filter:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                       items: const [
                         DropdownMenuItem(value: 'All', child: Text('All')),
                         DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                         DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                         DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                         DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                         DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                       ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _selectedFilter = v;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _FilteredActiveList(selectedFilter: _selectedFilter)),
        ],
      ),
    );
  }
}


class _FilteredActiveList extends StatelessWidget {
  final String selectedFilter; // All, Pending, Confirmed, In Progress, Cancelled

  const _FilteredActiveList({required this.selectedFilter});

  Stream<QuerySnapshot> _buildQuery(String userId, String selected) {
    final base = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId);

     Query query;
     switch (selected) {
       case 'Pending':
         // Check for both lowercase and capitalized versions
         query = base.where('status', whereIn: ['pending']);
         break;
       case 'Confirmed':
         query = base.where('status', whereIn: ['confirmed']);
         break;
       case 'In Progress':
         query = base.where('status', whereIn: ['in_progress']);
         break;
       case 'Completed':
         query = base.where('status', whereIn: ['completed']);
         break;
       case 'Cancelled':
         query = base.where('status', whereIn: ['cancelled']);
         break;
       default: // 'All'
         query = base; // Show ALL service records without status filter
     }
    
    // Always return snapshots without orderBy to avoid missing date field issues
    // We'll sort in memory instead
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to view services'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(user.uid, selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Force refresh by rebuilding the widget
                    (context as Element).markNeedsBuild();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFFC107))));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No services found'));
        }

        final docs = snapshot.data!.docs.toList();
        debugPrint('Found ${docs.length} documents for filter: $selectedFilter');
        
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          try {
            final aDate = _parseDateSafely(aData['date']);
            final bDate = _parseDateSafely(bData['date']);
            return aDate.compareTo(bDate);
          } catch (e) {
            debugPrint('Error sorting dates: $e');
            // If date comparison fails, sort by document ID as fallback
            return a.id.compareTo(b.id);
          }
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _BookingCard(data: data, bookingDocId: doc.id);
          },
        );
      },
    );
  }

}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String bookingDocId;

  const _BookingCard({required this.data, required this.bookingDocId});

  @override
  Widget build(BuildContext context) {
    final bookingIdDisplay = data['bookingId']?.toString() ?? bookingDocId;
    final serviceType = data['serviceType']?.toString() ?? 'Service';
    final location = data['location']?.toString() ?? data['workshopName']?.toString() ?? 'Service Location';
    final date = _parseDate(data['date']);
    final time = (data['time']?.toString() ?? '').trim();
    final status = (data['status']?.toString().toLowerCase() ?? '');
    final statusText = _statusDisplayText(status).toUpperCase();
    final Color statusColor = _statusDisplayColor(status);

    final plateNumber = data['plateNumber']?.toString() ?? 'N/A';
    final brand = data['brand']?.toString() ?? '';
    final model = data['model']?.toString() ?? '';
    final mobileNumber = data['mobileNumber']?.toString() ?? 'N/A';
    final notes = data['notes']?.toString() ?? '';

    String vehicleInfo = plateNumber;
    if (brand.isNotEmpty && model.isNotEmpty) {
      vehicleInfo = '$plateNumber ($brand $model)';
    } else if (brand.isNotEmpty) {
      vehicleInfo = '$plateNumber ($brand)';
    } else if (model.isNotEmpty) {
      vehicleInfo = '$plateNumber ($model)';
    }

    // Days until service chip (only for pending, confirmed, in_progress)
    final now = DateTime.now();
    final sd = DateTime(date.year, date.month, date.day);
    final cd = DateTime(now.year, now.month, now.day);
    final int diffDays = sd.difference(cd).inDays;
    String? daysLabel;
    final bool showDaysChip = status == 'pending' || status == 'confirmed' || status == 'in_progress';
    if (showDaysChip) {
      if (diffDays == 0) {
        daysLabel = 'Today';
      } else if (diffDays == 1) {
        daysLabel = 'In 1 day';
      } else if (diffDays > 1) {
        daysLabel = 'In $diffDays days';
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top info row: Booking ID + status pill
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking ID: $bookingIdDisplay',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Service title
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
              serviceType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),

          // Date + time row + days chip
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  time.isEmpty ? '-' : time,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (daysLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text(
                      daysLabel,
                      style: TextStyle(fontSize: 10, color: Colors.orange[700], fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Vehicle row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconBox(Icons.directions_car_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(vehicleInfo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Workshop and Contact row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconBox(Icons.location_on_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Workshop', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(location, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconBox(Icons.phone_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contact', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(mobileNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBox(Icons.note_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(notes, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Full-width View Details button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveStatusDetailPage(bookingId: bookingDocId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('View Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _iconBox(IconData icon) {
  return Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC107).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Icon(icon, size: 16, color: const Color(0xFFFFC107)),
  );
}

DateTime _parseDate(dynamic date) {
  if (date is Timestamp) return date.toDate();
  if (date is String) {
    final parsed = DateTime.tryParse(date);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

DateTime _parseDateSafely(dynamic date) {
  try {
    if (date is Timestamp) {
      return date.toDate();
    }
    if (date is String && date.isNotEmpty) {
      final parsed = DateTime.tryParse(date);
      if (parsed != null) {
        return parsed;
      }
    }
    if (date is int) {
      // Handle Unix timestamp in milliseconds
      return DateTime.fromMillisecondsSinceEpoch(date);
    }
    // If date is null or invalid, return a very old date so it sorts last
    return DateTime(1900);
  } catch (e) {
    debugPrint('Error parsing date: $date, error: $e');
    return DateTime(1900);
  }
}


String _statusDisplayText(String status) {
  switch (status) {
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

Color _statusDisplayColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange[600]!;
    case 'confirmed':
      return Colors.blue[600]!;
    case 'in_progress':
      return Colors.purple[600]!;
    case 'completed':
      return Colors.green[600]!;
    case 'cancelled':
      return Colors.red[600]!;
    default:
      return Colors.grey[600]!;
  }
}