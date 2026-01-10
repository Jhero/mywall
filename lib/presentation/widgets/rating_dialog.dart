import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _requestReview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Implementasi in_app_review
      // final InAppReview inAppReview = InAppReview.instance;
      // final isAvailable = await inAppReview.isAvailable();
      
      // if (isAvailable) {
      //   await inAppReview.requestReview();
      // } else {
      //   await inAppReview.openStoreListing();
      // }
      
      // Simulasi delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Maaf, tidak dapat membuka rating.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.star_rounded, color: Colors.amber[700], size: 28),
          const SizedBox(width: 8),
          const Text("Rate Our App"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Apakah Anda menikmati aplikasi kami?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Berikan rating untuk membantu kami berkembang! ⭐",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text("Nanti Saja"),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _requestReview,
          icon: const Icon(Icons.star, size: 18),
          label: const Text("Beri Rating"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}