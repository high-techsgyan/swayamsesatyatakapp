class Quote {
  final String id;
  final String image;
  final String text;
  final String author;
  int likesCount;
  int commentsCount;

  Quote({
    required this.id,
    required this.image,
    required this.text,
    required this.author,
    required this.likesCount,
    required this.commentsCount,
  });
   factory Quote.fromMap(Map<dynamic, dynamic> data, String id) {
    return Quote(
      id: id,
      image: data['imageUrl'] ?? '',
      text: data['quote'] ?? '',
      author: data['author'] ?? 'Unknown',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
    );
  }
}