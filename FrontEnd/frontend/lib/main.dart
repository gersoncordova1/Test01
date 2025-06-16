import 'package:flutter/material.dart';
import 'package:studyroom_app/screens/auth_screen.dart'; // Importa AuthScreen desde su nueva ubicación

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyRoom App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthScreen(), // La aplicación inicia en AuthScreen
    );
  }
}
