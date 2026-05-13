import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleSignInButton({
  required VoidCallback? onPressed,
  required bool isLoading,
}) {
  return AbsorbPointer(
    absorbing: isLoading || onPressed == null,
    child: SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: google_web.renderButton(),
      ),
    ),
  );
}
