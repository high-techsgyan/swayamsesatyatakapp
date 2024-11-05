// lib/custom_input_icon_button.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Make sure GoRouter is imported if you're using it.

class CustomInputIconButton extends StatelessWidget {
  final String placeholderText;
  final String route;

  const CustomInputIconButton({
    Key? key,
    this.placeholderText = "What's on your mind?",
    required this.route,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                context.push(route); // Navigates to the specified route
              },
              child: Text(
                placeholderText,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
