import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:swayamsesatyatak/screen/auth/login_screen.dart';
import 'package:swayamsesatyatak/screen/auth/register_screen.dart';
import 'package:swayamsesatyatak/screen/home_screen.dart';
import 'package:swayamsesatyatak/screen/profile_screen.dart';
import 'package:swayamsesatyatak/screen/splash_screen.dart';
import 'package:swayamsesatyatak/screen/walkthrough/walk_through.dart';
import 'package:swayamsesatyatak/views/bookviews/bookdetailsview.dart';
import 'package:swayamsesatyatak/views/dashboard_screen.dart';
import 'package:swayamsesatyatak/views/postviews/postdetailsscreen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter binding is initialized
  await Firebase.initializeApp(); // Initialize Firebase

  // No need to initialize InAppWebViewPlatform here; it's handled internally.

  runApp(const MyApp()); // Updated to run const MyApp
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Added constructor for const usage

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      initialLocation: determineInitialRoute(),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegistrationScreen(),
        ),
        GoRoute(
          path: '/book',
          builder: (context, state) => const BookScreen(),
        ),
        GoRoute(
          path: '/walkthrough',
          builder: (context, state) => WalkThrough(),
        ),
        GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
        GoRoute(
            path: '/dashborad', builder: (context, state) => DashboardScreen()),
        GoRoute(
          path: '/postDetails',
          builder: (context, state) {
            final postDoc = state.extra as DocumentSnapshot;
            return PostDetailsScreen(postDoc: postDoc);
          },
        ),
        GoRoute(
          path: '/bookDetails',
          builder: (context, state) {
            final bookDoc = state.extra as DocumentSnapshot;
            return BookDetailsScreen(
              bookDoc: bookDoc,
              userId: '',
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: _router,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
    );
  }

  String determineInitialRoute() {
    if (kIsWeb) {
      return '/home'; // Default route for web
    } else if (Platform.isAndroid) {
      return '/'; // Default route for Android
    } else {
      return '/home'; // Default route for other platforms
    }
  }
}

class BookScreen extends StatelessWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Book Screen')); // Book screen content
  }
}
