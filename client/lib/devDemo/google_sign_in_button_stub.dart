import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required VoidCallback? onPressed,
  required bool isLoading,
}) {
  return OutlinedButton.icon(
    onPressed: isLoading ? null : onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.black87,
      minimumSize: const Size.fromHeight(48),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    icon: Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFDB4437),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    label: Text(isLoading ? 'Signing in...' : 'Sign in with Google'),
  );
}
