import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swayamsesatyatak/models/qoute_model.dart';

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

  Future<void> _submitQuote() async {
    if (_newQuote.isNotEmpty) {
      final newQuoteRef = _quotesRef.push();
      await newQuoteRef.set({
        'text': _newQuote,
        'author': FirebaseAuth.instance.currentUser!.uid,
        'likes': {},
        'comments': {},
        'likesCount': 0,
        'commentsCount': 0,
      });
      _showSuccessDialog('Quote added successfully!');
      setState(() {
        _newQuote = '';
      });
    } else {
      _showErrorDialog('Please enter a quote.');
    }
  }

  Future<void> _toggleLikeQuote(Quote quote) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference quoteLikeRef =
          _quotesRef.child(quote.id).child('likes').child(user.uid);
      final DatabaseReference userLikesRef =
          _usersRef.child(user.uid).child('likes').child(quote.id);

      final DatabaseEvent event = await quoteLikeRef.once();
      if (event.snapshot.exists) {
        await quoteLikeRef.remove();
        await userLikesRef.remove();
        final newLikesCount = quote.likesCount - 1;
        await _quotesRef.child(quote.id).update({'likesCount': newLikesCount});
        setState(() {
          quote.likesCount = newLikesCount;
        });
        _showSuccessDialog('You unliked this post!');
      } else {
        await quoteLikeRef.set(true);
        await userLikesRef.set(true);
        final newLikesCount = quote.likesCount + 1;
        await _quotesRef.child(quote.id).update({'likesCount': newLikesCount});
        setState(() {
          quote.likesCount = newLikesCount;
        });
        _showSuccessDialog('You liked this post!');
      }
    } else {
      _showErrorDialog('You need to be logged in to like a quote.');
    }
  }

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

      await commentRef.set(commentData);
      await userCommentsRef.set(commentData);
      final newCommentsCount = currentCommentsCount + 1;
      await _quotesRef
          .child(quoteId)
          .update({'commentsCount': newCommentsCount});
      setState(() {
        currentCommentsCount = newCommentsCount;
      });
      _showSuccessDialog('Comment added successfully!');
    } else {
      _showErrorDialog('You need to be logged in to comment.');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildDailyQuotesTab(),
    );
  }

  Widget _buildDailyQuotesTab() {
    return Column(
      children: [
        _buildAdminInputField(),
        Expanded(child: _buildQuoteList()),
      ],
    );
  }

  Widget _buildAdminInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey[200],
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.push('/quote');
              },
              child: Text(
                "what's in Your Mind",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                imageUrl: quotes[index].image,
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
}

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

class QuoteCard extends StatelessWidget {
  final String imageUrl;
  final Quote quote;
  final VoidCallback onLike;
  final Function(String) onComment;
  final VoidCallback onShowComments;

  const QuoteCard({
    Key? key,
    required this.imageUrl,
    required this.quote,
    required this.onLike,
    required this.onComment,
    required this.onShowComments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text(quote.author),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Linkify(
                  onOpen: (link) async {
                    final url = Uri.parse(link.url);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  text: quote.text,
                  style: TextStyle(fontSize: 16.0),
                  linkStyle: TextStyle(color: Colors.blue),
                ),
                const SizedBox(height: 8),
                if (imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FullScreenImage(url: imageUrl),
                        ),
                      );
                    },
                    child: Image.network(imageUrl),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.thumb_up_alt_outlined),
                onPressed: onLike,
              ),
              Text('${quote.likesCount}'),
              IconButton(
                icon: Icon(Icons.comment),
                onPressed: onShowComments,
              ),
              Text('${quote.commentsCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String url;

  const FullScreenImage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Image.network(url),
      ),
    );
  }
}
