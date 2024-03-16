import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CognitoService {

  final userPool = CognitoUserPool(
    dotenv.get("COGNITO_USER_POOL_ID"),
    dotenv.get("COGNITO_CLIEND_ID"),
  );

  Future<CognitoUserSession?> signIn(String username, String password) async {
    final cognitoUser = CognitoUser(username, userPool);
    final authDetails = AuthenticationDetails(
      username: username,
      password: password,
    );

    CognitoUserSession? session;
    try {
      session = await cognitoUser.authenticateUser(authDetails);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }

    return session;
  }
}
