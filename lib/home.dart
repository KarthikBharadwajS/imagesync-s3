import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imagesync/aws/s3_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final S3Service _s3Service = S3Service();
  List<String> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _folders = prefs.getStringList('folders') ?? [];
    });
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> distinctFolders = _folders.toSet().toList();
    await prefs.setStringList('folders', distinctFolders);
  }

  Future<void> _selectFolders() async {
    if (await Permission.storage.request().isGranted) {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _folders.add(result);
        });
        await _saveFolders();
        await _uploadFolderContents(result);
      }
    } else {
      // Permission denied
      _showErrorDialog('Permission Denied', 'Storage permission is required to access files.');
    }
    
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadFolderContents(String folderPath) async {
    final directory = Directory(folderPath);
    debugPrint(directory.toString());

    final List<FileSystemEntity> files1 = await directory.list(recursive: true).toList();

    debugPrint('Files found in directory: $files1');

    final files = directory.listSync(recursive: true).whereType<File>();
    debugPrint(files.toString());
    for (var file in files) {
        await _s3Service.uploadFile(file.path, file.uri.pathSegments.last);
    }
  }

  Future<void> _syncFolder(String folderPath) async {
    await _uploadFolderContents(folderPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_folders[index]),
            trailing: IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _syncFolder(_folders[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectFolders,
        child: const Icon(Icons.add),
      ),
    );
  }
}