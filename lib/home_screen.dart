import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final String udid;

  const HomeScreen({required this.udid, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Успешная авторизация \r\nUdid: ${widget.udid}',style: const TextStyle(fontSize: 22),),
        ),
      ),
    );
  }
}
