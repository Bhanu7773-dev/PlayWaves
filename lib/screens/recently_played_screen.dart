import 'package:flutter/material.dart';

class RecentlyPlayedScreen extends StatelessWidget {
  const RecentlyPlayedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Played'),
      ),
      body: const Center(
        child: Text(
          'This is the Recently Played page.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}