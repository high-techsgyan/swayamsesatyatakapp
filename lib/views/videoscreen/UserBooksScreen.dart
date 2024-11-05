import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class UserBooksScreen extends StatefulWidget {
  @override
  _UserBooksScreenState createState() => _UserBooksScreenState();
}

class _UserBooksScreenState extends State<UserBooksScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _realtimeDB = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> userBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserBooks();
  }

  // Fetches book IDs from Realtime Database and retrieves book details from Firestore
  Future<void> _fetchUserBooks() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Get the list of book IDs from the user's record in Realtime Database
        final booksRef = _realtimeDB.ref('Users/${user.uid}/books');
        final snapshot = await booksRef.get();

        if (snapshot.exists && snapshot.value != null) {
          // Fetch book details from Firestore
          List<Map<String, dynamic>> booksList = [];
          for (final bookId in (snapshot.value as Map).keys) {
            final bookDoc =
                await _firestore.collection('books').doc(bookId).get();
            if (bookDoc.exists) {
              booksList.add({
                'bookId': bookId,
                'name': bookDoc['name'],
                'description': bookDoc['description'],
              });
            }
          }
          setState(() {
            userBooks = booksList;
          });
        }
      } catch (e) {
        print("Error fetching books: $e");
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Books')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userBooks.isEmpty
              ? Center(child: Text('No Books'))
              : ListView.builder(
                  itemCount: userBooks.length,
                  itemBuilder: (context, index) {
                    final book = userBooks[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(book['name']),
                        subtitle: Text(book['description']),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            context.push('/bookpage');
          },
          child: Text('Buy Book'),
        ),
      ),
    );
  }
}
