import 'package:flutter/material.dart';
import 'package:swayamsesatyatak/screen/auth/login_screen.dart';
import 'package:swayamsesatyatak/screen/auth/register_screen.dart';

class WalkThrough extends StatefulWidget {
  @override
  _WalkThroughState createState() => _WalkThroughState();
}

class _WalkThroughState extends State<WalkThrough> {
  double? currentPage = 0;
  PageController _pageController = PageController();
  List<Widget> pages = [];

  static const _kDuration = Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page;
      });
    });

    // Initialize pages with styled boxes around images
    pages = [
      buildImageBox('assets/images/walkthrough/walkthrough1.webp'),
      buildImageBox('assets/images/walkthrough/walkthrough2.webp'),
      buildImageBox('assets/images/walkthrough/walkthrough3.webp'),
    ];
  }

  Widget buildImageBox(String imagePath) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Image/Pages Section
          Expanded(
            child: PageView(
              controller: _pageController,
              children: pages,
            ),
          ),

          // Bottom Container with Text and Buttons
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    'Welcome', // Title Text
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Your journey starts here.', // Subtitle Text
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16),

                // Button Row with Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegistrationScreen()),
                        );
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),

                    // Page Indicators
                    Row(
                      children: List.generate(
                        pages.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: currentPage?.round() == index ? 12 : 8,
                          height: currentPage?.round() == index ? 12 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPage?.round() == index
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    // Next/Start Button
                    TextButton(
                      onPressed: () {
                        if ((currentPage?.round() ?? 0) < pages.length - 1) {
                          _pageController.nextPage(
                              duration: _kDuration, curve: _kCurve);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        }
                      },
                      child: Text(
                        (currentPage?.round() ?? 0) == pages.length - 1
                            ? 'Start'
                            : 'Next',
                        style: TextStyle(
                          color: (currentPage?.round() ?? 0) == pages.length - 1
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
