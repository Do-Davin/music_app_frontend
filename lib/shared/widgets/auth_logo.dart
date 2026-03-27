import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  final double? height;

  const AuthLogo({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Logo.png',
      height: height ?? 240, // default = 240
    );
  }
}
