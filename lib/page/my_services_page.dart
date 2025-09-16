import 'package:flutter/material.dart';
import 'upcoming_services_page.dart';
import 'overdate_service_page.dart';
import 'active_status_selector_page.dart';

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  final int _selectedIndex = 2; // My Services tab selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'My Services',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Three Main Service Cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Upcoming/Past Services Card
                  _buildServiceCard(
                    icon: _buildCalendarIcon(),
                    buttonText: 'Upcoming/Past Services',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UpcomingServicesPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Active Service Status Card
                  _buildServiceCard(
                    icon: _buildHourglassIcon(),
                    buttonText: 'Active Service Status',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActiveStatusSelectorPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Overdate Service Card
                  _buildServiceCard(
                    icon: _buildToolsIcon(),
                    buttonText: 'Overdate Service',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OverdateServicePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildServiceCard({
    required Widget icon,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Icon
            icon,
            const SizedBox(height: 20),
            
            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Calendar top part
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Calendar body with number
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!, width: 2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: const Center(
              child: Text(
                '17',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourglassIcon() {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: HourglassPainter(),
      ),
    );
  }

  Widget _buildToolsIcon() {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: ToolsPainter(),
      ),
    );
  }




  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          _handleBottomNavigation(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'My Services',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _handleBottomNavigation(int index) {
    if (index == _selectedIndex) return; // Already on this page
    
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Book
        Navigator.pushReplacementNamed(context, '/book');
        break;
      case 2: // My Services (current page)
        // Already on this page, do nothing
        break;
      case 3: // Billing
        // Navigate to Billing page when implemented
        break;
      case 4: // Profile
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}

class HourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    const double hourglassWidth = 40;
    const double hourglassHeight = 50;

    // Draw hourglass outline
    final path = Path();
    
    // Top part
    path.moveTo(center.dx - hourglassWidth / 2, center.dy - hourglassHeight / 2);
    path.lineTo(center.dx + hourglassWidth / 2, center.dy - hourglassHeight / 2);
    path.lineTo(center.dx + hourglassWidth / 2, center.dy - hourglassHeight / 4);
    path.lineTo(center.dx, center.dy);
    path.lineTo(center.dx - hourglassWidth / 2, center.dy - hourglassHeight / 4);
    path.close();

    // Bottom part
    path.moveTo(center.dx - hourglassWidth / 2, center.dy + hourglassHeight / 2);
    path.lineTo(center.dx + hourglassWidth / 2, center.dy + hourglassHeight / 2);
    path.lineTo(center.dx + hourglassWidth / 2, center.dy + hourglassHeight / 4);
    path.lineTo(center.dx, center.dy);
    path.lineTo(center.dx - hourglassWidth / 2, center.dy + hourglassHeight / 4);
    path.close();

    canvas.drawPath(path, paint);

    // Draw sand in bottom
    final sandPaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;

    final sandPath = Path();
    sandPath.moveTo(center.dx - hourglassWidth / 4, center.dy + hourglassHeight / 2);
    sandPath.lineTo(center.dx + hourglassWidth / 4, center.dy + hourglassHeight / 2);
    sandPath.lineTo(center.dx + hourglassWidth / 6, center.dy + hourglassHeight / 4);
    sandPath.lineTo(center.dx - hourglassWidth / 6, center.dy + hourglassHeight / 4);
    sandPath.close();

    canvas.drawPath(sandPath, sandPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ToolsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw wrench
    final wrenchPath = Path();
    wrenchPath.moveTo(center.dx - 15, center.dy - 20);
    wrenchPath.lineTo(center.dx - 15, center.dy - 10);
    wrenchPath.lineTo(center.dx - 20, center.dy - 5);
    wrenchPath.lineTo(center.dx - 15, center.dy);
    wrenchPath.lineTo(center.dx - 10, center.dy - 5);
    wrenchPath.lineTo(center.dx - 15, center.dy - 10);
    wrenchPath.lineTo(center.dx - 5, center.dy - 10);
    wrenchPath.lineTo(center.dx + 5, center.dy);
    wrenchPath.lineTo(center.dx + 10, center.dy - 5);
    wrenchPath.lineTo(center.dx + 5, center.dy - 10);

    canvas.drawPath(wrenchPath, paint);

    // Draw screwdriver
    canvas.drawLine(
      Offset(center.dx + 5, center.dy - 15),
      Offset(center.dx + 20, center.dy + 15),
      paint,
    );

    // Screwdriver handle
    final handlePaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx + 13, center.dy + 5),
      Offset(center.dx + 20, center.dy + 15),
      handlePaint,
    );

    // Add crossing circle
    final circlePaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(center.dx, center.dy - 5),
      18,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
