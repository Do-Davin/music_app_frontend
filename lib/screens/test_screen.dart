import 'package:flutter/material.dart';
import 'package:music_app_frontend/widgets/app_error_button.dart';
import 'package:music_app_frontend/widgets/app_password_field.dart';
import 'package:music_app_frontend/widgets/app_primary_button.dart';
import 'package:music_app_frontend/widgets/app_secondary_button.dart';
import 'package:music_app_frontend/widgets/app_text_field.dart';
import 'package:music_app_frontend/widgets/app_warning_button.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
