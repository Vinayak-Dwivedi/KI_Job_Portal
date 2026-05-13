import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OtpLoadingOverlay extends StatelessWidget {
  final String message;
  const OtpLoadingOverlay({super.key, this.message = 'Verifying OTP...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie animation for verification - using a high-quality external URL
              // as fallback if local isn't available
              SizedBox(
                height: 120,
                child: Lottie.network(
                  'https://lottie.host/8040d73a-4467-466d-9781-a75d506a77d1/9r7ZtY7C5l.json',
                  errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we secure your account',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
