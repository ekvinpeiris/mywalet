import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

abstract class FirestoreModel {
  Map<String, dynamic> toMap();
  String? get id;
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamController<bool> connectionStateController = StreamController<bool>.broadcast();

  FirestoreService() {
    // Monitor connection state
    _firestore.snapshotsInSync().listen((_) {
      connectionStateController.add(true);
    });
  }

  String? get currentUserId => _auth.currentUser?.uid;

  // Create
  Future<DocumentReference> create(String collection, FirestoreModel data) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    try {
      return await _firestore.collection(collection).add({
        ...data.toMap(),
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Firestore create error: ${e.code} - ${e.message}');
      throw _handleFirestoreError(e);
    }
  }

  // Read one
  Future<DocumentSnapshot> getById(String collection, String id) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (!doc.exists) throw Exception('Document not found');
      return doc;
    } on FirebaseException catch (e) {
      print('Firestore read error: ${e.code} - ${e.message}');
      throw _handleFirestoreError(e);
    }
  }

  // Read all
  Stream<QuerySnapshot> getAll(String collection, {
    List<List<dynamic>>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      Query query = _firestore.collection(collection);

      // Apply where conditions if provided
      if (whereConditions != null) {
        for (var condition in whereConditions) {
          if (condition.length == 3) {
            query = query.where(condition[0], isEqualTo: condition[1]);
          }
        }
      }

      // Add default user ID filter
      query = query.where('userId', isEqualTo: currentUserId);

      // Apply ordering if provided
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots();
    } on FirebaseException catch (e) {
      print('Firestore query error: ${e.code} - ${e.message}');
      throw _handleFirestoreError(e);
    }
  }

  // Update
  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (!doc.exists) throw Exception('Document not found');
      
      // Verify ownership
      if (doc.data()?['userId'] != currentUserId) {
        throw Exception('Unauthorized access');
      }

      await _firestore.collection(collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print('Firestore update error: ${e.code} - ${e.message}');
      throw _handleFirestoreError(e);
    }
  }

  // Delete
  Future<void> delete(String collection, String id) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (!doc.exists) throw Exception('Document not found');
      
      // Verify ownership
      if (doc.data()?['userId'] != currentUserId) {
        throw Exception('Unauthorized access');
      }

      await _firestore.collection(collection).doc(id).delete();
    } on FirebaseException catch (e) {
      print('Firestore delete error: ${e.code} - ${e.message}');
      throw _handleFirestoreError(e);
    }
  }

  // Batch operations
  Future<void> batchUpdate(String collection, List<FirestoreModel> items) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    try {
      final batch = _firestore.batch();
      
      for (var item in items) {
        if (item.id != null) {
          final docRef = _firestore.collection(collection).doc(item.id);
          // Verify ownership first
          final doc = await docRef.get();
          if (!doc.exists || doc.data()?['userId'] != currentUserId) {
            throw Exception('Unauthorized access to one or more documents');
          }
          
          batch.update(docRef, {
            ...item.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
    } on FirebaseException catch (e) {
      print('Firestore batch update error: ${e.code} - ${e.message}');
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Permission denied. Please check your access rights.');
      case 'unavailable':
        return Exception('Service temporarily unavailable. Please check your internet connection.');
      case 'not-found':
        return Exception('Document not found.');
      case 'already-exists':
        return Exception('Document already exists.');
      case 'failed-precondition':
        return Exception('Operation failed. The service might be temporarily unavailable.');
      case 'unauthenticated':
        return Exception('Authentication required. Please sign in again.');
      case 'cancelled':
        return Exception('Operation cancelled.');
      default:
        return Exception('An error occurred: ${e.message}');
    }
  }

  void dispose() {
    connectionStateController.close();
  }
}