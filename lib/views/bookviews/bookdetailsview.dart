import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class BookDetailsScreen extends StatelessWidget {
  final DocumentSnapshot bookDoc;
  final String userId;

  BookDetailsScreen({required this.bookDoc, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(bookDoc['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                bookDoc['coverUrl'],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.error, color: Colors.red));
                },
              ),
            ),
            SizedBox(height: 16),
            Text(
              bookDoc['name'],
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Author: ${bookDoc['author']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Description: ${bookDoc['description']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Hard Copy Price: \$${bookDoc['hardCopyPrice']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Soft Copy Price: \$${bookDoc['softCopyPrice']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return FutureBuilder<DatabaseEvent>(
      future: FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(userId)
          .child('books')
          .once(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        bool bookOwned = false;

        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          Map<String, dynamic> booksMap =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          // Loop through each book entry and check if bookId matches bookDoc.id
          for (var entry in booksMap.entries) {
            var bookData = Map<String, dynamic>.from(entry.value);
            print("Checking bookId in user's books: ${bookData['bookId']}");
            if (bookData['bookId'] == bookDoc.id) {
              bookOwned = true;
              break;
            }
          }
        } else {
          print("User does not own any books or data structure is empty.");
        }

        return ElevatedButton(
          onPressed: () {
            if (bookOwned) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PDFViewerScreen(bookId: bookDoc.id, pdfUrl: ''),
                ),
              );
            } else {
              final bookUrl =
                  'https://swayamsesatyatak.web.app/book/${bookDoc['slug']}';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BuyBookScreen(bookUrl: bookUrl),
                ),
              );
            }
          },
          child: Text(bookOwned ? 'View Book' : 'Buy Book'),
        );
      },
    );
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String bookId;
  final String pdfUrl;

  PDFViewerScreen({required this.bookId, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("View Book")),
      body: Center(child: Text("Viewing Book ID: $bookId")),
    );
  }
}

class BuyBookScreen extends StatelessWidget {
  final String bookUrl;

  BuyBookScreen({required this.bookUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Buy Book")),
      body: Center(
        child: Text("Buying Book from URL: $bookUrl"),
      ),
    );
  }
}
