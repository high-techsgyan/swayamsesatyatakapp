import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swayamsesatyatak/services/image_upload.dart';

class PostQuoteScreen extends StatefulWidget {
  const PostQuoteScreen({Key? key}) : super(key: key);

  @override
  _PostQuoteScreenState createState() => _PostQuoteScreenState();
}

class _PostQuoteScreenState extends State<PostQuoteScreen> {
  final TextEditingController _quoteController = TextEditingController();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('Users');
  final List<TextEditingController> _optionControllers = [];
  int _optionCount = 2; // Starting with two options for the poll
  bool _isPollVisible = false; // Flag to show/hide poll input fields
  bool _isQuizVisible = false; // Flag to show/hide quiz input fields
  int? _correctAnswerIndex;
  String? _imageUrl; // Index of the correct answer for the quiz

  @override
  void initState() {
    super.initState();
    // Initialize with two empty option controllers
    _optionControllers.add(TextEditingController());
    _optionControllers.add(TextEditingController());
    _checkIfAdmin();
  }

  @override
  void dispose() {
    // Dispose of controllers
    _quoteController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
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

  Future<void> uploadImage(BuildContext context) async {
    final imageUrl = await ImageUploadService.pickAndUploadImage(context);
    if (imageUrl != null) {
      setState(() {
        _imageUrl = imageUrl;
      });
      print("Uploaded Image URL: $_imageUrl");
    } else {
      _showErrorDialog("Image upload failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post an Update'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _submitUpdate,
            tooltip: 'Submit',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Dismiss the keyboard when tapping outside the text field
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter your ${_isQuizVisible ? 'Quiz' : _isPollVisible ? 'Poll' : 'Update'}:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quoteController,
                          maxLines: null,
                          maxLength: 1000, // Limit to 1000 characters
                          decoration: InputDecoration(
                            hintText: _isQuizVisible
                                ? 'Quiz your community...'
                                : _isPollVisible
                                    ? 'Ask your community...'
                                    : 'Post your update...',
                            border: InputBorder.none,
                            counterText:
                                '${1000 - _quoteController.text.length} characters remaining', // Show remaining characters
                          ),
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        if (_isPollVisible || _isQuizVisible) ...[
                          Text(
                            _isQuizVisible ? 'Quiz Options:' : 'Poll Options:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._buildOptionInputs(),
                          if (_optionCount <
                              4) // Show add option button if less than 4
                            ElevatedButton(
                              onPressed: _addOption,
                              child: const Text('Add Option'),
                            ),
                          if (_isQuizVisible) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Select the correct answer:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            _buildCorrectAnswerSelector(),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptionInputs() {
    return List<Widget>.generate(_optionCount, (index) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _optionControllers[index],
              decoration: InputDecoration(
                hintText: 'Option ${index + 1}',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _removeOption(index),
            tooltip: 'Delete Option',
          ),
        ],
      );
    });
  }

  Widget _buildCorrectAnswerSelector() {
    return DropdownButton<int>(
      value: _correctAnswerIndex,
      hint: const Text('Select correct answer'),
      onChanged: (int? newValue) {
        setState(() {
          _correctAnswerIndex = newValue;
        });
      },
      items: List<DropdownMenuItem<int>>.generate(_optionCount, (index) {
        return DropdownMenuItem<int>(
          value: index,
          child: Text('Option ${index + 1}'),
        );
      }),
    );
  }

  void _addOption() {
    if (_optionCount < 4) {
      setState(() {
        _optionCount++;
        _optionControllers.add(
            TextEditingController()); // Add a new controller for the new option
      });
    }
  }

  void _removeOption(int index) {
    if (_optionCount > 2) {
      // Minimum of two options
      setState(() {
        _optionControllers[index]
            .dispose(); // Dispose of the removed controller
        _optionControllers.removeAt(index);
        _optionCount--;
        // Adjust the correct answer index if necessary
        if (_correctAnswerIndex == index) {
          _correctAnswerIndex = null; // Reset if the correct answer was removed
        } else if (_correctAnswerIndex != null &&
            _correctAnswerIndex! > index) {
          _correctAnswerIndex = _correctAnswerIndex! - 1; // Adjust the index
        }
      });
    }
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        if (_imageUrl != null)
          GestureDetector(
            onTap: () => _showFullScreenImage(
                context, _imageUrl!), // Show image in full screen
            child: Container(
              width: 100, // Medium box width
              height: 100, // Medium box height
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: NetworkImage(_imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () =>
              uploadImage(context), // Call uploadImage with context
          child: const Text("Upload Image"),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.poll),
              onPressed: _togglePollVisibility,
              tooltip: 'Add Poll',
            ),
            IconButton(
              icon: const Icon(Icons.quiz),
              onPressed: _toggleQuizVisibility,
              tooltip: 'Add Quiz',
            ),
          ],
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        );
      },
    );
  }

  void _togglePollVisibility() {
    setState(() {
      _isPollVisible = !_isPollVisible; // Toggle poll input visibility
      if (_isPollVisible) {
        _isQuizVisible = false; // Hide quiz if showing poll
      }
      _resetOptions(); // Reset options when toggling
    });
  }

  void _toggleQuizVisibility() {
    setState(() {
      _isQuizVisible = !_isQuizVisible; // Toggle quiz input visibility
      if (_isQuizVisible) {
        _isPollVisible = false; // Hide poll if showing quiz
      }
      _resetOptions(); // Reset options when toggling
    });
  }

  void _resetOptions() {
    _optionControllers.clear();
    _optionCount = 2; // Reset to two options
    _correctAnswerIndex = null; // Reset correct answer index
    _optionControllers.add(TextEditingController());
    _optionControllers.add(TextEditingController());
  }

  void _submitUpdate() async {
    if (_quoteController.text.isNotEmpty) {
      final String createdTime = DateTime.now().toIso8601String();
      List<String> options =
          _optionControllers.map((controller) => controller.text).toList();

      // Prepare data for submission
      Map<String, dynamic> data = {
        'quote': _quoteController.text,
        'imageUrl': _imageUrl ?? '', // Use the already uploaded imageUrl
        'author': FirebaseAuth.instance.currentUser!.uid,
        'createdTime': createdTime,
        'likes': {},
        'comments': {},
        'likesCount': 0,
        'commentsCount': 0,
      };

      if (_isQuizVisible) {
        // Prepare quiz data
        if (_correctAnswerIndex == null) {
          _showError('Please select the correct answer for the quiz.');
          return;
        }

        DatabaseReference ref =
            FirebaseDatabase.instance.ref().child('quizzes').push();
        ref.set({
          'question': _quoteController.text,
          'options': options.where((option) => option.isNotEmpty).toList(),
          'correctAnswerIndex': _correctAnswerIndex,
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'createdTime': createdTime,
        }).then((_) {
          print('Quiz submitted successfully!');
        }).catchError((error) {
          print('Failed to submit quiz: $error');
        });
      } else if (_isPollVisible) {
        // Prepare poll data
        DatabaseReference ref =
            FirebaseDatabase.instance.ref().child('polls').push();
        ref.set({
          'question': _quoteController.text,
          'options': options.where((option) => option.isNotEmpty).toList(),
          'votes': [],
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'createdTime': createdTime,
        }).then((_) {
          print('Poll submitted successfully!');
        }).catchError((error) {
          print('Failed to submit poll: $error');
        });
      } else {
        // Submit the quote
        DatabaseReference ref =
            FirebaseDatabase.instance.ref().child('quotes').push();
        ref.set(data).then((_) {
          print('Quote submitted successfully!');
        }).catchError((error) {
          print('Failed to submit quote: $error');
        });
      }

      // Reset fields after submission
      _quoteController.clear();
      for (var controller in _optionControllers) {
        controller.clear(); // Clear option inputs
      }
      setState(() {
        _imageUrl = null; // Reset the image URL
        _optionCount = 2; // Reset to two options
        _isPollVisible = false; // Hide poll inputs
        _isQuizVisible = false; // Hide quiz inputs
        _correctAnswerIndex = null; // Reset correct answer index
        _resetOptions(); // Reset options if necessary
      });

      // Close the screen
      Navigator.of(context).pop();
    } else {
      _showError('Please enter a message or question.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
