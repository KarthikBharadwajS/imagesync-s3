import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login.dart';
import 'home.dart';
import 'package:permission_handler/permission_handler.dart';

import 'aws/cognito_service.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); // mergeWith optional, you can include Platform.environment for Mobile/Desktop app

  // Request necessary permissions
  await _requestPermissions();

  runApp(const Root());
}

Future<void> _requestPermissions() async {
    // Requesting storage permission
  PermissionStatus status = await Permission.storage.status;
  if (status.isDenied) {
    await Permission.storage.request();
  }
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _isAuthenticated = false;
  final CognitoService _cognitoService = CognitoService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final session = await _cognitoService.getSession();
    setState(() {
      _isAuthenticated = session != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Cognito Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
