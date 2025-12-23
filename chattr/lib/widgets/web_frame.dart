import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebFrame extends StatelessWidget {
  final Widget child;

  const WebFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        color: Colors.grey[200], // Background for empty space
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450), // Mobile width constraint
          height: double.infinity,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            // Optional: rounded corners for the "phone" look
            // borderRadius: BorderRadius.circular(20), 
            child: child,
          ),
        ),
      );
    }
    return child;
  }
}
