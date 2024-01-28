import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:revelationsai/src/utils/build_context_extensions.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Oops! Something went wrong.',
              style: context.textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () {
                context.go("/home");
              },
              child: Text(
                'Go back to home',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.secondaryColor,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
