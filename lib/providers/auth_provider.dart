import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_data.dart';
import '../models/corps_data.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  UserData? _userData;
  CorpsData? _corpsData;
  Map<String, Map<String, String>> _attendance = {}; // dateId -> { uid -> status }
  int _staffCount = 0;
  bool _loading = true;

  User? get user => _user;
  UserData? get userData => _userData;
  CorpsData? get corpsData => _corpsData;
  Map<String, Map<String, String>> get attendance => _attendance;
  int get staffCount => _staffCount;
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
        _attendance = {};
        _staffCount = 0;
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
          _listenToAttendanceData(_userData!.corpsId);
          _listenToStaffCount(_userData!.corpsId);
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

  void _listenToStaffCount(String corpsId) {
    _db.collection('users')
      .where('corpsId', isEqualTo: corpsId)
      .where('isArchived', isNotEqualTo: true)
      .snapshots()
      .listen((snapshot) {
        _staffCount = snapshot.docs.length;
        notifyListeners();
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

  void _listenToAttendanceData(String corpsId) {
    _db.collection('corps').doc(corpsId).collection('attendance').snapshots().listen((snapshot) {
      final Map<String, Map<String, String>> newAttendance = {};
      for (var doc in snapshot.docs) {
        newAttendance[doc.id] = Map<String, String>.from(doc.data()['statuses'] ?? {});
      }
      _attendance = newAttendance;
      notifyListeners();
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> uploadCorpsLogo() async {
    if (_corpsData == null) {
      debugPrint('Error: _corpsData is null');
      return;
    }

    debugPrint('Attempting to open image picker...');
    final picker = ImagePicker();
    XFile? image;
    
    try {
      image = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 1024, // Increased for better quality
        maxHeight: 1024,
        imageQuality: 90,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }

    if (image != null) {
      debugPrint('Image picked: ${image.path}');
      final storageRef = FirebaseStorage.instance.ref();
      final logoRef = storageRef.child('corps_logos/${_corpsData!.id}.png');

      try {
        debugPrint('Reading bytes...');
        final bytes = await image.readAsBytes();
        
        debugPrint('Uploading to storage...');
        await logoRef.putData(bytes, SettableMetadata(contentType: 'image/png'));
        
        debugPrint('Getting download URL...');
        final downloadUrl = await logoRef.getDownloadURL();
        
        debugPrint('Updating Firestore...');
        await _db.collection('corps').doc(_corpsData!.id).update({
          'logoUrl': downloadUrl,
        });
        
        // No need to manually update _corpsData because the listener in _listenToCorpsData 
        // will trigger when the document changes and notify listeners.
        debugPrint('Logo upload complete: $downloadUrl');
      } catch (e) {
        debugPrint('Error uploading logo: $e');
        rethrow;
      }
    } else {
      debugPrint('No image selected');
    }
  }

  Future<void> deleteCorpsLogo() async {
    if (_corpsData == null || _corpsData!.logoUrl == null) return;

    final storageRef = FirebaseStorage.instance.ref();
    final logoRef = storageRef.child('corps_logos/${_corpsData!.id}.png');

    try {
      // Delete from storage
      await logoRef.delete();
      
      // Update Firestore
      await _db.collection('corps').doc(_corpsData!.id).update({
        'logoUrl': null,
      });
    } catch (e) {
      debugPrint('Error deleting logo: $e');
      // Even if storage delete fails (e.g. file already gone), update Firestore
      await _db.collection('corps').doc(_corpsData!.id).update({
        'logoUrl': null,
      });
    }
  }
}
