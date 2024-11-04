import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _quotesRef = FirebaseDatabase.instance.ref('quotes');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  String _newQuote = '';
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkIfAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference userRef = _usersRef.child(user.uid);
      final DatabaseEvent event = await userRef.once();
      final DataSnapshot userSnapshot = event.snapshot;

      if (userSnapshot.exists) {
        setState(() {});
      } else {
        _showErrorDialog('User not found.');
      }
    } else {
      _showErrorDialog('User is not logged in.');
    }
  }

  Future<List<Quote>> _fetchQuotes() async {
    final DatabaseEvent event = await _quotesRef.once();
    final DataSnapshot snapshot = event.snapshot;

    List<Quote> quotes = [];
    if (snapshot.exists) {
      final quotesData = snapshot.value as Map<dynamic, dynamic>;
      quotesData.forEach((key, value) {
        quotes.add(Quote.fromMap(value, key)); // Pass the key (quote ID)
      });
    }
    return quotes;
  }

  // Submit a new quote
  Future<void> _submitQuote() async {
    if (_newQuote.isNotEmpty) {
      final newQuoteRef = _quotesRef.push();
      await newQuoteRef.set({
        'text': _newQuote,
        'author': FirebaseAuth.instance.currentUser!.email,
        'likes': {}, // Initialize an empty map for likes
        'comments': {}, // Initialize an empty map for comments
        'likesCount': 0, // Initialize the like count
        'commentsCount': 0, // Initialize the comment count
      });
      _showSuccessDialog('Quote added successfully!');
      setState(() {
        _newQuote = ''; // Clear the input field
      });
    } else {
      _showErrorDialog('Please enter a quote.');
    }
  }

  // Toggle Like/Unlike a quote
  Future<void> _toggleLikeQuote(Quote quote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference quoteLikeRef =
          _quotesRef.child(quote.id).child('likes').child(user.uid);
      final DatabaseReference userLikesRef =
          _usersRef.child(user.uid).child('likes').child(quote.id);

      final DatabaseEvent event = await quoteLikeRef.once();
      if (event.snapshot.exists) {
        // User has already liked, so unlike
        await quoteLikeRef.remove();
        await userLikesRef.remove();
        final newLikesCount = quote.likesCount - 1;
        await _quotesRef.child(quote.id).update({'likesCount': newLikesCount});
        setState(() {
          quote.likesCount = newLikesCount; // Update the local count
        });
        _showSuccessDialog('You unliked this post!');
      } else {
        // User has not liked, so like
        await quoteLikeRef.set(true);
        await userLikesRef.set(true);
        final newLikesCount = quote.likesCount + 1;
        await _quotesRef.child(quote.id).update({'likesCount': newLikesCount});
        setState(() {
          quote.likesCount = newLikesCount; // Update the local count
        });
        _showSuccessDialog('You liked this post!');
      }
    } else {
      _showErrorDialog('You need to be logged in to like a quote.');
    }
  }

  // Comment on a quote
  Future<void> _commentOnQuote(
      String quoteId, String commentText, int currentCommentsCount) async {
    if (commentText.isEmpty) {
      _showErrorDialog('Please enter a comment.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference commentRef =
          _quotesRef.child(quoteId).child('comments').push();
      final DatabaseReference userCommentsRef =
          _usersRef.child(user.uid).child('comments').child(quoteId).push();

      final commentData = {
        'text': commentText,
        'author': user.email,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await commentRef.set(commentData); // Add the comment under the post
      await userCommentsRef
          .set(commentData); // Add the comment under the user profile
      final newCommentsCount = currentCommentsCount + 1;
      await _quotesRef
          .child(quoteId)
          .update({'commentsCount': newCommentsCount});
      setState(() {
        // Increment the count in the UI
        currentCommentsCount = newCommentsCount;
      });
      _showSuccessDialog('Comment added successfully!');
    } else {
      _showErrorDialog('You need to be logged in to comment.');
    }
  }

  // Get comments for a quote
  Future<List<Comment>> _fetchComments(String quoteId) async {
    final DatabaseReference commentsRef =
        _quotesRef.child(quoteId).child('comments');
    final DatabaseEvent event = await commentsRef.once();
    final DataSnapshot snapshot = event.snapshot;

    List<Comment> comments = [];
    if (snapshot.exists) {
      final commentsData = snapshot.value as Map<dynamic, dynamic>;
      commentsData.forEach((key, value) {
        comments.add(Comment.fromMap(value, key));
      });
    }
    return comments;
  }

  // Error and success dialog handlers
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _extractVideoId(String url) {
    final RegExp regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
      multiLine: false,
    );
    final match = regExp.firstMatch(url);
    return match != null && match.groupCount > 0 ? match.group(1)! : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildDailyQuotesTab(),
    );
  }

  // Build Daily Quotes Tab
  Widget _buildDailyQuotesTab() {
    return Column(
      children: [
        _buildAdminInputField(), // Show input field for admins
        Expanded(child: _buildQuoteList()), // Show quotes list
      ],
    );
  }

  // Admin Input Field
  Widget _buildAdminInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _newQuote = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Enter a daily quote...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _submitQuote,
          ),
        ],
      ),
    );
  }

  // Display List of Quotes
  Widget _buildQuoteList() {
    return FutureBuilder<List<Quote>>(
      future: _fetchQuotes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final quotes = snapshot.data ?? [];
          return ListView.builder(
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              return QuoteCard(
                quote: quotes[index],
                onLike: () => _toggleLikeQuote(quotes[index]),
                onComment: (commentText) => _commentOnQuote(
                    quotes[index].id, commentText, quotes[index].commentsCount),
                onShowComments: () => _showCommentsDialog(quotes[index].id),
              );
            },
          );
        }
      },
    );
  }

  // Show Comments Dialog
  Future<void> _showCommentsDialog(String quoteId) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<Comment>>(
          future: _fetchComments(quoteId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final comments = snapshot.data ?? [];
              String newComment = '';

              return AlertDialog(
                title: const Text('Comments'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show existing comments
                    if (comments.isNotEmpty)
                      ...comments.map((comment) => ListTile(
                            title: Text(comment.text),
                            subtitle: Text('- ${comment.author}'),
                          )),
                    const Divider(),
                    // Input field to add new comment
                    TextField(
                      onChanged: (value) => newComment = value,
                      decoration:
                          const InputDecoration(hintText: 'Add a comment...'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (newComment.isNotEmpty) {
                        _commentOnQuote(quoteId, newComment, comments.length);
                        Navigator.of(context).pop();
                      } else {
                        _showErrorDialog('Please enter a comment.');
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'YouTube Video URL'),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  bool _isValidYouTubeUrl(String url) {
    final RegExp regex = RegExp(
      r'^(https?\:\/\/)?(www\.youtube\.com|youtu\.?be)\/.+$',
      caseSensitive: false,
      multiLine: false,
    );
    return regex.hasMatch(url);
  }

  void _showdErrorDialog(List<String> errorMessages) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: errorMessages.map((msg) => Text(msg)).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showdSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Quote Model
class Quote {
  final String id;
  final String text;
  final String author;
  int likesCount;
  int commentsCount;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.likesCount,
    required this.commentsCount,
  });

  factory Quote.fromMap(Map<dynamic, dynamic> data, String id) {
    return Quote(
      id: id,
      text: data['text'] ?? '',
      author: data['author'] ?? 'Unknown',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
    );
  }
}

// Comment Model
class Comment {
  final String id;
  final String text;
  final String author;

  Comment({required this.id, required this.text, required this.author});

  factory Comment.fromMap(Map<dynamic, dynamic> data, String id) {
    return Comment(
      id: id,
      text: data['text'] ?? '',
      author: data['author'] ?? 'Unknown',
    );
  }
}

// QuoteCard Widget
class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onLike;
  final ValueChanged<String> onComment;
  final VoidCallback onShowComments;

  const QuoteCard({
    Key? key,
    required this.quote,
    required this.onLike,
    required this.onComment,
    required this.onShowComments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('- ${quote.author}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up),
                      onPressed: onLike,
                    ),
                    Text('${quote.likesCount}'), // Show likes count
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment),
                      onPressed: onShowComments, // Show comments dialog
                    ),
                    Text('${quote.commentsCount}'), // Show comments count
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
