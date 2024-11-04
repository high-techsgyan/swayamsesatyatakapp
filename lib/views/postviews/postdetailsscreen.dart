import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_html/flutter_html.dart';

class PostDetailsScreen extends StatelessWidget {
  final DocumentSnapshot postDoc;

  PostDetailsScreen({required this.postDoc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(postDoc['title']),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Displaying the image with error handling
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  postDoc['image'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Icon(Icons.error, color: Colors.red));
                  },
                ),
              ),
              SizedBox(height: 16),
              
              // Displaying the title
              Text(
                postDoc['title'],
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              
              // Displaying the description
              Text(
                postDoc['description'],
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              
              // Displaying the category
              if (postDoc['category'].isNotEmpty)
                Text(
                  'Category: ${postDoc['category']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              SizedBox(height: 8),

              // Displaying the tags
              if (postDoc['tags'].isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  children: List<Widget>.from(
                    postDoc['tags'].map((tag) => Chip(label: Text(tag))),
                  ),
                ),
              SizedBox(height: 16),

              // Displaying the creation date
              Text(
                'Published on: ${DateTime.parse(postDoc['createdAt']).toLocal().toString().split(' ')[0]}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 16),

              // Displaying the content as HTML
              Html(
                data: postDoc['content'], // Ensure this contains your HTML content
                style: {
                  "body": Style(
                    fontSize: FontSize(16.0), // Default font size
                    lineHeight: LineHeight(1.5), // Spacing between lines
                  ),
                  "h1": Style(
                    fontSize: FontSize(24.0),
                    fontWeight: FontWeight.bold,
                  ),
                  "h2": Style(
                    fontSize: FontSize(22.0),
                    fontWeight: FontWeight.bold,
                  ),
                  "h3": Style(
                    fontSize: FontSize(20.0),
                    fontWeight: FontWeight.bold,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
