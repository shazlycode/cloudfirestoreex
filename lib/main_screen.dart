import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("cloud firestore rtd ex".toUpperCase()),
      ),
      body: Center(
        child: Text("Cloud firestore rtd ex".toUpperCase()),
      ),
    );
  }
}
