import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_framework/flutter_mvvm_framework.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'views/user_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mock server backend for interactive preview
  final List<Map<String, dynamic>> demoUsers = [
    {
      'id': 1,
      'name': 'Sarah Connor',
      'email': 'sarah.connor@example.com',
      'role': 'Lead Architect',
    },
    {
      'id': 2,
      'name': 'Alex Rivera',
      'email': 'alex.rivera@example.com',
      'role': 'Mobile Engineer',
    },
    {
      'id': 3,
      'name': 'Emma Watson',
      'email': 'emma.watson@design.co',
      'role': 'UX Designer',
    },
  ];

  final mockClient = MockClient((request) async {
    final path = request.url.path;

    if (path == '/users' && request.method == 'GET') {
      return http.Response(jsonEncode(demoUsers), 200, headers: {'content-type': 'application/json'});
    }

    if (path == '/users' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final newUser = {
        'id': demoUsers.length + 1,
        'name': body['name'] ?? 'New Member',
        'email': body['email'] ?? 'member@example.com',
        'role': body['role'] ?? 'Contributor',
      };
      demoUsers.insert(0, newUser);
      return http.Response(jsonEncode(newUser), 201, headers: {'content-type': 'application/json'});
    }

    return http.Response(jsonEncode({'message': 'Not Found'}), 404);
  });

  // Initialize MVVM framework
  await MVVM.initialize(
    baseUrl: 'https://api.example.com',
    httpClient: mockClient,
    logging: true,
  );

  runApp(const MvvmExampleApp());
}

class MvvmExampleApp extends StatelessWidget {
  const MvvmExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MVVM Framework Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const UserPage(),
    );
  }
}
