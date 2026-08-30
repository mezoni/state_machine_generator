import 'dart:convert';

import 'package:crypto/crypto.dart';

class AuthService {
  static final Map<String, String> _users = {};

  Future<User> login(String login, String password) async {
    final hash = _users[login];
    if (hash == null) {
      _error();
    }

    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    if (hash != digest.toString()) {
      _error();
    }

    await Future<void>.delayed(Duration(seconds: 3));
    return User(login);
  }

  Future<void> logout(User? user) async {
    await Future<void>.delayed(Duration(seconds: 3));
  }

  Future<User> register(String login, String password) async {
    if (_users.containsKey(login)) {
      return throw StateError("User '$login' already exists");
    }

    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();
    _users[login] = hash;
    await Future<void>.delayed(Duration(seconds: 3));
    return User(login);
  }

  Never _error() {
    throw StateError('Invalid login or password');
  }
}

class User {
  final String login;

  User(this.login);

  @override
  String toString() {
    return login;
  }
}
