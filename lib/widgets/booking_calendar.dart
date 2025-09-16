import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingCalendar extends StatefulWidget {
  final Function(DateTime date, String time) onSlotSelected;

  const BookingCalendar({
    super.key,
    required this.onSlotSelected,
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  Map<String, Map<String, String>> _availability = {};
  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '14:00',
    '15:00', '16:00', '17:00', '18:00'
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final DateTime firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final DateTime lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final QuerySnapshot bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
        .get();

    Map<String, Map<String, String>> availability = {};

    DateTime currentDay = firstDay;
    while (currentDay.isBefore(lastDay) || currentDay == lastDay) {
      if (currentDay.weekday <= 5) {
        String dateKey = DateFormat('yyyy-MM-dd').format(currentDay);
        availability[dateKey] = {};
        for (String time in _timeSlots) {
          availability[dateKey]![time] = 'available';
        }
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    for (var doc in bookings.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final DateTime bookingDate = (data['date'] as Timestamp).toDate();
      final String dateKey = DateFormat('yyyy-MM-dd').format(bookingDate);
      final String timeSlot = data['time'];

      if (availability.containsKey(dateKey) && 
          availability[dateKey]!.containsKey(timeSlot)) {
        if (availability[dateKey]![timeSlot] == 'available') {
          availability[dateKey]![timeSlot] = 'partial';
        } else if (availability[dateKey]![timeSlot] == 'partial') {
          availability[dateKey]![timeSlot] = 'full';
        }
      }
    }

    availability.removeWhere((key, _) {
      final date = DateFormat('yyyy-MM-dd').parse(key);
      return date.isBefore(DateTime.now());
    });

    setState(() {
      _availability = availability;
    });
  }

  void _onPreviousMonth() {
    if (_selectedMonth.isAfter(DateTime.now()) ||
        (_selectedMonth.year == DateTime.now().year &&
         _selectedMonth.month > DateTime.now().month)) {
      setState(() {
        _selectedMonth = DateTime(
          _selectedMonth.year,
          _selectedMonth.month - 1,
        );
        _selectedDate = null;
      });
      _loadAvailability();
    }
  }

  void _onNextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
      _selectedDate = null;
    });
    _loadAvailability();
  }

  Widget _buildDateCell(DateTime date) {
    final isSelected = _selectedDate?.year == date.year &&
        _selectedDate?.month == date.month &&
        _selectedDate?.day == date.day;

    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final isPastDate = date.isBefore(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ));

    return Container(
      height: 36,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: const Color(0xFFFFC107), width: 1) : null,
      ),
      child: TextButton(
        onPressed: isPastDate ? null : () {
          setState(() {
            _selectedDate = date;
            _selectedTime = null; // Reset time selection when date changes
          });
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: isSelected ? Colors.black : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
              color: isPastDate 
                  ? Colors.grey[400]
                  : isSelected 
                      ? Colors.black 
                      : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  List<List<Widget>> _buildCalendarWeeks() {
    final List<List<Widget>> weeks = [];
    final DateTime firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final DateTime lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    // Calculate the first Monday we should start from
    DateTime currentDate = firstDay;
    while (currentDate.weekday > 1) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    // Build weeks until we've shown all days of the month
    while (currentDate.isBefore(lastDay) || currentDate == lastDay) {
      List<Widget> currentWeek = [];

      // Build each weekday (Mon-Fri)
      for (int weekday = 1; weekday <= 5; weekday++) {
        if (currentDate.month == _selectedMonth.month) {
          currentWeek.add(Expanded(child: _buildDateCell(currentDate)));
        } else {
          currentWeek.add(const Expanded(child: SizedBox.shrink()));
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // Skip weekend days
      currentDate = currentDate.add(const Duration(days: 2));
      
      // Add the week if it has any days from current month
      if (currentWeek.isNotEmpty) {
        weeks.add(currentWeek);
      }
    }

    return weeks;
  }

  String? _selectedTime;

  Widget _buildTimeSlot(String time) {
    if (_selectedDate == null) return const SizedBox.shrink();

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final availability = _availability[dateKey]?[time] ?? 'full';
    final isSelected = _selectedTime == time;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ElevatedButton(
        onPressed: availability == 'full'
            ? null
            : () {
                setState(() {
                  _selectedTime = time;
                });
                widget.onSlotSelected(_selectedDate!, time);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFFFFC107)
              : availability == 'full'
                  ? Colors.grey[200]
                  : availability == 'partial'
                      ? Colors.white
                      : Colors.white,
          foregroundColor: Colors.black87,
          elevation: isSelected ? 2 : 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFFFC107)
                  : availability == 'full'
                      ? Colors.grey[300]!
                      : availability == 'partial'
                          ? Colors.orange
                          : const Color(0xFFFFC107),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(DateFormat('HH:mm').parse(time)),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: availability == 'full' 
                        ? Colors.grey[500]
                        : isSelected ? Colors.black : Colors.black87,
                  ),
                ),
                if (availability != 'full')
                  Text(
                    availability == 'partial'
                        ? '1 slot available'
                        : '2 slots available',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: availability == 'partial'
                          ? Colors.orange[700]
                          : Colors.green[700],
                    ),
                  ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  availability == 'full'
                      ? Icons.block
                      : availability == 'partial'
                          ? Icons.person
                          : Icons.check_circle_outline,
                  size: 20,
                  color: availability == 'full'
                      ? Colors.grey
                      : availability == 'partial'
                          ? Colors.orange
                          : Colors.green,
                ),
                if (availability == 'full')
                  Text(
                    'Fully booked',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _onPreviousMonth,
                color: const Color(0xFFFFC107),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _onNextMonth,
                color: const Color(0xFFFFC107),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: _buildCalendarWeeks()
                .map(
                  (week) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: week,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Selected date display
        if (_selectedDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event,
                    color: Color(0xFFFFC107),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDate!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Time slots
        if (_selectedDate != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20),
                SizedBox(width: 8),
                Text(
                  'Available Time Slots',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._timeSlots.map(_buildTimeSlot),
        ],
      ],
    );
  }
}