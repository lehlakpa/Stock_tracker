import 'package:flutter/material.dart';
import '../widgets/error_state_widget.dart';

class SetupErrorScreen extends StatelessWidget {
  final String message;
  const SetupErrorScreen({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Firebase setup')),
    body: ErrorStateWidget(message: message),
  );
}
