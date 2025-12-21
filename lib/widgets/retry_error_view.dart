import 'package:flutter/material.dart';

class RetryErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String buttonText;

  const RetryErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.buttonText = 'Coba Lagi',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
