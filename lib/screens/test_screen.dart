// lib/screens/test_screen.dart

import 'package:flutter/material.dart';
import 'package:music_app_frontend/widgets/app_error_button.dart';
import 'package:music_app_frontend/widgets/app_password_field.dart';
import 'package:music_app_frontend/widgets/app_primary_button.dart';
import 'package:music_app_frontend/widgets/app_secondary_button.dart';
import 'package:music_app_frontend/widgets/app_text_field.dart';
import 'package:music_app_frontend/widgets/app_warning_button.dart';

// This screen is just for testing your reusable widgets.
// It is NOT a real app screen — you can delete it later.
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Prevents overflow on small screens
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppTextField(
              label: 'Email',
              hint: 'Enter email',
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            AppPasswordField(label: 'Password', hint: 'Enter password'),
            const SizedBox(height: 16),
            AppPrimaryButton(label: 'Primary', onPressed: () {}),
            const SizedBox(height: 16),
            AppSecondaryButton(label: 'Secondary', onPressed: () {}),
            const SizedBox(height: 16),
            AppWarningButton(label: 'Warning', onPressed: () {}),
            const SizedBox(height: 16),
            AppErrorButton(label: 'Logout', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
