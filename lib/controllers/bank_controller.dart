import '../services/firestore_service.dart';
import '../models/bank.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BankController {
  final FirestoreService _service = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collection = 'banks';

  // Create new bank
  Future<DocumentReference> createBank(String bankName) async {
    if (_service.currentUserId == null) {
      throw Exception('User must be logged in to create a bank');
    }
    
    if (bankName.trim().isEmpty) {
      throw Exception('Bank name cannot be empty');
    }

    try {
      final bank = Bank(
        bankName: bankName.trim(),
        userId: _service.currentUserId!,
      );
      return await _service.create(collection, bank);
    } on FirebaseException catch (e) {
      throw Exception('Failed to create bank: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create bank: $e');
    }
  }

  // Get all banks for current user
  Stream<List<Bank>> getBanks() {
    return _service
        .getAll(
          collection,
          whereConditions: [
            ['userId', _service.currentUserId]
          ],
          orderBy: 'bankName',
        )
        .map((snapshot) =>
            snapshot.docs.map((doc) => Bank.fromFirestore(doc)).toList());
  }

  // Get all banks without user filter
  Future<List<Bank>> getAllBanks() async {
    final snapshot = await _service.getAll(
      collection,
      orderBy: 'bankName',
    ).first;
    return snapshot.docs.map((doc) => Bank.fromFirestore(doc)).toList();
  }

  // Get bank by ID
  Future<Bank?> getBankById(String bankId) async {
    final doc = await _service.getById(collection, bankId);
    if (!doc.exists) return null;
    
    final bank = Bank.fromFirestore(doc);
    if (bank.userId != _service.currentUserId) {
      throw Exception('Unauthorized access');
    }
    return bank;
  }

  // Update bank
  Future<void> updateBank(String bankId, String bankName) async {
    if (_service.currentUserId == null) {
      throw Exception('User must be logged in to update a bank');
    }
    
    if (bankName.trim().isEmpty) {
      throw Exception('Bank name cannot be empty');
    }

    final bank = await getBankById(bankId);
    if (bank == null) throw Exception('Bank not found');
    
    final updatedBank = Bank(
      id: bankId,
      bankName: bankName.trim(),
      userId: _service.currentUserId!,
    );
    
    try {
      await _service.update(collection, bankId, updatedBank.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to update bank: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update bank: $e');
    }
  }

  // Delete bank
  Future<void> deleteBank(String bankId) async {
    if (_service.currentUserId == null) {
      throw Exception('User must be logged in to delete a bank');
    }

    final bank = await getBankById(bankId);
    if (bank == null) throw Exception('Bank not found');
    
    try {
      await _service.delete(collection, bankId);
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete bank: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete bank: $e');
    }
  }

  // Get total funds across all banks for authenticated user
  Future<double> getTotalFunds() async {
    if (_service.currentUserId == null) {
      return 0.0;
    }

    try {
      final banksSnapshot = await _firestore.collection('banks')
          .where('userId', isEqualTo: _service.currentUserId)
          .get();
      
      double totalFunds = 0.0;
      for (var bankDoc in banksSnapshot.docs) {
        final accountsSnapshot = await bankDoc.reference
            .collection('accounts')
            .where('userId', isEqualTo: _service.currentUserId)
            .get();

        for (var accountDoc in accountsSnapshot.docs) {
          totalFunds += accountDoc.data()['balance'] ?? 0.0;
        }
      }
      
      return totalFunds;
    } catch (e) {
      print('Error calculating total funds: $e');
      return 0.0;
    }
  }
}