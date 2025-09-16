import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/booking_calendar.dart';

class BookServiceFormPage extends StatefulWidget {
  const BookServiceFormPage({super.key});

  @override
  State<BookServiceFormPage> createState() => _BookServiceFormPageState();
}

class _BookServiceFormPageState extends State<BookServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  String? _selectedServiceType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedLocation;
  final _mobileNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // Service type options
  final List<String> _serviceTypes = [
    'Oil Change',
    'Brake Inspection',
    'Engine Diagnostic',
    'Aircond Service',
    'Wheel Alignment & Balancing',
    'General Maintenance',
  ];

  // Workshop locations
  final List<String> _locations = [
    'Setapak Carcare+ Service Center',
    'Kepong Carcare+ Service Center',
    'Shah Alam Carcare+ Service Center',
    'Petaling Jaya Carcare+ Service Center',
    'Puchong Carcare+ Service Center',
    'Sri-petaling Carcare+ Service Center',
    'Balakong Carcare+ Service Center',
    'Subang Carcare+ Service Center',
  ];


  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _normalizePhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '+60${phone.substring(1)}';
    }
    return phone;
  }

  Future<void> _submitBooking() async {
    if (_formKey.currentState!.validate() && _validateForm()) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withValues(alpha: 26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFFFFC107),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Are you sure you want to proceed with this booking?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black87,
                            elevation: 0,
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
                          onPressed: () => Navigator.of(context).pop(true),
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
                            'Confirm',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (confirm == true) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
             debugPrint('Submitting booking for user: ${user.uid}');
             final bookingData = {
              'userId': user.uid,
              'plateNumber': _plateNumberController.text.trim(),
              'brand': _brandController.text.trim(),
              'model': _modelController.text.trim(),
              'serviceType': _selectedServiceType,
              'date': Timestamp.fromDate(_selectedDate!),
              'time': _formatTimeOfDay(_selectedTime!),
              'location': _selectedLocation,
              'mobileNumber': _normalizePhoneNumber(_mobileNumberController.text.trim()),
              'notes': _notesController.text.trim(),
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            };
            
              debugPrint('Submitting booking data: $bookingData');
              
              // Query the latest booking to get the last booking ID
              final latestBookingQuery = await FirebaseFirestore.instance
                  .collection('bookings')
                  .orderBy('createdAt', descending: true)
                  .limit(1)
                  .get();

              // Generate the next booking ID
              String nextBookingId;
              if (latestBookingQuery.docs.isEmpty) {
                nextBookingId = 'B0001';
              } else {
                final lastBooking = latestBookingQuery.docs.first.data();
                final lastBookingId = lastBooking['bookingId'] as String? ?? 'B0000';
                final lastNumber = int.parse(lastBookingId.substring(1));
                nextBookingId = 'B${(lastNumber + 1).toString().padLeft(4, '0')}';
              }
              debugPrint('Generated next booking ID: $nextBookingId');

              // Add the booking ID to the booking data
              bookingData['bookingId'] = nextBookingId;
              
              final docRef = await FirebaseFirestore.instance
                  .collection('bookings')
                  .add(bookingData);
                  
              debugPrint('Booking created with doc ID: ${docRef.id} and booking ID: $nextBookingId}');

            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking submitted successfully'),
                  backgroundColor: Color(0xFFFFC107),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to submit booking. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  bool _validateForm() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return false;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return false;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return false;
    }
    return true;
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFFC107)),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      // Make input text black
      floatingLabelStyle: const TextStyle(color: Color(0xFFFFC107)),
      hintStyle: TextStyle(color: Colors.grey[500]),
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
        title: const Text(
          'Book a Service',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Details Section
              Text(
                'Vehicle Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Plate Number
              TextFormField(
                controller: _plateNumberController,
                decoration: _getInputDecoration('Plate Number').copyWith(
                  hintText: 'such as ABC1234',
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plate number';
                  }
                  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
                    return 'Only letters and numbers allowed';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Convert to uppercase as user types
                  final upperValue = value.toUpperCase();
                  if (upperValue != value) {
                    _plateNumberController.value = _plateNumberController.value.copyWith(
                      text: upperValue,
                      selection: TextSelection.collapsed(offset: upperValue.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: _getInputDecoration('Brand').copyWith(
                  hintText: 'such as Honda'
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter brand';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Model
              TextFormField(
                controller: _modelController,
                decoration: _getInputDecoration('Car Model').copyWith(
                  hintText: 'such as City'
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter car model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Service Details Section
              Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Service Type
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedServiceType,
                  decoration: _getInputDecoration('Service Type').copyWith(
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                  ),
                  icon: const SizedBox.shrink(), // Hide the default icon
                  isExpanded: true,
                  items: _serviceTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedServiceType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a service type';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date and Time Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Date & Time',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedDate != null && _selectedTime != null)
                            Text(
                              '${DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!)} at ${_formatTimeOfDay(_selectedTime!)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            )
                          else
                            Text(
                              '* Please select a date and time below\n'
                              '* Each of the time slot has 2 slots available\n'
                              '* You are not allowed to book the pass time slot\n'
                              '* The booking should be book one day in advance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    BookingCalendar(
                      onSlotSelected: (date, time) {
                        setState(() {
                          _selectedDate = date;
                          final parts = time.split(':');
                          _selectedTime = TimeOfDay(
                            hour: int.parse(parts[0]),
                            minute: int.parse(parts[1]),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Location Details Section
              Text(
                'Location Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Location Selection
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: _getInputDecoration('Select Location').copyWith(
                    suffixIcon: Icon(
                      Icons.location_on_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                  icon: const SizedBox.shrink(), // Hide the default icon
                  isExpanded: true,
                  items: _locations.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a location';
                    }
                    return null;
                  },
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Contact Details Section
              Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),

              // Mobile Number
              TextFormField(
                controller: _mobileNumberController,
                decoration: _getInputDecoration('Mobile Number').copyWith(
                  hintText: '+60123456789 or 0123456789',
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  // Regex for Malaysian phone numbers
                  final phoneRegex = RegExp(r'^(?:\+60|0)[0-9]{9,10}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Please enter a valid Malaysian phone number';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Remove any whitespace
                  _mobileNumberController.text = value.replaceAll(RegExp(r'\s+'), '');
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: _getInputDecoration('Notes (Optional)')
                    .copyWith(alignLabelWithHint: true),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit and Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _mobileNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}