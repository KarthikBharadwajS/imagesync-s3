import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import "package:aws_s3_api/s3-2006-03-01.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'cognito_service.dart';


class S3Service {
  final CognitoService _cognitoService = CognitoService();

  Future<void> uploadFile(String filePath, String fileName) async {
    final credentials = await _cognitoService.getTemporaryCredentials();
    final accessKeyId = credentials?.accessKeyId;
    final secretAccessKey = credentials?.secretAccessKey;
    if (credentials == null && accessKeyId == null && secretAccessKey == null) {
      throw Exception('Failed to get AWS credentials');
    }

    final s3 = S3(
      region: dotenv.get("S3_BUCKET_REGION"),
      credentials: AwsClientCredentials(
        accessKey: accessKeyId as String,
        secretKey: secretAccessKey as String,
        sessionToken: credentials?.sessionToken,
      ),
    );

    try {
      final file = File(filePath);
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();

      final request = s3.putObject(
        bucket: dotenv.get("S3_BUCKET_NAME"),
        key: fileName,
        body: stream as Uint8List,
        contentLength: length,
        contentType: 'image/jpeg', // Adjust content type as necessary
      );

      await request.asStream();
      print('File uploaded successfully');
    } catch (e) {
      print('File upload failed: $e');
    }
  }
}
