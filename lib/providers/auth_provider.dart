
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_data.dart';
import '../models/corps_data.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  UserData? _userData;
  CorpsData? _corpsData;
  bool _loading = true;

  User? get user => _user;
  UserData? get userData => _userData;
  CorpsData? get corpsData => _corpsData;
  bool get loading => _loading;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user == null) {
        _userData = null;
        _corpsData = null;
        _loading = false;
        notifyListeners();
      } else {
        _listenToUserData(user.uid);
      }
    });
  }

  void _listenToUserData(String uid) {
    _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        _userData = UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (_userData?.corpsId != null && _userData?.corpsId != 'PENDING') {
          _listenToCorpsData(_userData!.corpsId);
        } else {
          _loading = false;
          notifyListeners();
        }
      } else {
        _userData = null;
        _loading = false;
        notifyListeners();
      }
    });
  }

  void _listenToCorpsData(String corpsId) {
    _db.collection('corps').doc(corpsId).snapshots().listen((doc) {
      if (doc.exists) {
        _corpsData = CorpsData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        _corpsData = null;
      }
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
