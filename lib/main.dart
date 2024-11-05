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
import 'package:swayamsesatyatak/screen/update_page.dart';
import 'package:swayamsesatyatak/screen/walkthrough/walk_through.dart';
import 'package:swayamsesatyatak/services/donation_screen.dart';
import 'package:swayamsesatyatak/views/bookviews/bookdetailsview.dart';
import 'package:swayamsesatyatak/views/communityviews/post_quote_screen.dart';
import 'package:swayamsesatyatak/views/dashboard_screen.dart';
import 'package:swayamsesatyatak/views/postviews/bookspage_screen.dart';
import 'package:swayamsesatyatak/views/postviews/postdetailsscreen.dart';
import 'package:swayamsesatyatak/views/postviews/userdonationscreen.dart';
import 'package:swayamsesatyatak/views/videoscreen/UserBooksScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
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
          path: '/bookpage',
          builder: (context, state) => BookScreenPage(),
        ),
        GoRoute(
          path: '/walkthrough',
          builder: (context, state) => WalkThrough(),
        ),
        GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
        GoRoute(
            path: '/dashboard', builder: (context, state) => DashboardScreen()),
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
        GoRoute(
          path: '/quote',
          builder: (context, state) => PostQuoteScreen(),
        ),
        GoRoute(
          path: '/userbooks',
          builder: (context, state) => UserBooksScreen(),
        ),
        GoRoute(
          path: '/userdonation',
          builder: (context, state) => UserDonationScreen(),
        ),
        GoRoute(
          path: '/donation',
          builder: (context, state) => DonationPage(),
        ),
        GoRoute(
  path: '/updatePage',
  builder: (context, state) {
    final apkUrl = state.extra as String; // Get the URL passed from the SplashScreen
    return UpdatePage(apkUrl: apkUrl);
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
