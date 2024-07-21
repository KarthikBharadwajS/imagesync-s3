import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CognitoService {
  final userPool = CognitoUserPool(
    dotenv.get("COGNITO_USER_POOL_ID"),
    dotenv.get("COGNITO_CLIEND_ID"),
  );

  Future<CognitoUserSession?> signIn(String username, String password, {String? newPassword, String? name}) async {
    final cognitoUser = CognitoUser(username, userPool);
    final authDetails = AuthenticationDetails(
      username: username,
      password: password,
    );

    CognitoUserSession? session;
    try {
      session = await cognitoUser.authenticateUser(authDetails);
      await _persistSession(session);
    } on CognitoUserNewPasswordRequiredException catch (e) {
      if (name != null && newPassword != null) {
        // collect username assigned, newpassword and call sendNewPasswordRequired
        final attributes = { "name": name };
        final session = await cognitoUser.sendNewPasswordRequiredAnswer(newPassword, attributes);
        return session;
      }
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }

    return session;
  }

  Future<void> _persistSession(CognitoUserSession? session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('idToken', session?.getIdToken().getJwtToken() as String);
    await prefs.setString('accessToken', session?.getAccessToken().getJwtToken() as String);
    await prefs.setString('refreshToken', session?.getRefreshToken()?.getToken() as String);
  }

  Future<CognitoUserSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final idToken = prefs.getString('idToken');
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (idToken == null || accessToken == null || refreshToken == null) {
      return null;
    }

    return CognitoUserSession(CognitoIdToken(idToken), CognitoAccessToken(accessToken), refreshToken: CognitoRefreshToken(refreshToken));
  }

  Future<CognitoUserSession?> checkSession() async {
    final cognitoUser = await userPool.getCurrentUser();
    if (cognitoUser == null) {
      return null;
    }
    try {
      final session = await cognitoUser.getSession();
      return session;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<CognitoCredentials?> getTemporaryCredentials() async {
    final cognitoUser = await userPool.getCurrentUser();
    if (cognitoUser == null) {
      return null;
    }
    try {
      final session = await cognitoUser.getSession();
      final credentials = CognitoCredentials(
        dotenv.get("COGNITO_USER_POOL_ID"),
        userPool,
      );

      final idToken = session?.getIdToken();

      if (idToken != null) {
        await credentials.getAwsCredentials(idToken.getJwtToken());
      }
      return credentials;
    } catch (e) {
      return null;
    }
  }
}
