import 'package:carcare/page/book_service_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'page/landing_page.dart';
import 'page/register_page.dart';
import 'page/login_page.dart';
import 'page/home_page.dart';
import 'page/forgot_password_page.dart';
import 'page/otp_verification_page.dart';
import 'page/reset_password_page.dart';
import 'page/profile_page.dart';
import 'page/edit_profile_page.dart';
import 'page/my_services_page.dart';
import 'page/billings.dart';
import 'services/invoice_service.dart';
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Flutter binding initialized');
    
    // Initialize Firebase
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    // Enable edge-to-edge display for perfect background coverage
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    debugPrint('System UI mode set');
    
    runApp(const MyApp());
    debugPrint('App started');
  } catch (e, stackTrace) {
    debugPrint('Error in main: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still try to run the app even if there's an error
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Care',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1a1a2e),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          debugPrint('Auth state changed: ${snapshot.connectionState}');
          
          // Handle errors
          if (snapshot.hasError) {
            debugPrint('Auth stream error: ${snapshot.error}');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Something went wrong'),
                    if (snapshot.error != null)
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            );
          }

          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('Waiting for auth state...');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                ),
              ),
            );
          }
          
          // If user is logged in, go to home page
          if (snapshot.hasData && snapshot.data != null) {
            debugPrint('User is logged in: ${snapshot.data?.uid}');
            // Start invoice monitoring for this user
            InvoiceService.startInvoiceMonitoring();
            // Process any existing completed bookings that don't have invoices
            InvoiceService.processExistingCompletedBookings();
            return const HomePage();
          }
          
          // If not logged in, show landing page
          debugPrint('User is not logged in, showing landing page');
          return const LandingPage();
        },
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/book': (context) => const BookServicePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/otp-verification': (context) => const OtpVerificationPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/landing': (context) => const LandingPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/my-services': (context) => const MyServicesPage(),
        '/billings': (context) => const BillingPage(),
      },
    );
  }
}


