import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_wallert/models/bank_account.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new account to a bank 
  Future<void> addAccount(String bankId, BankAccount bankAccount) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Ensure the account has the current user's ID and bank ID
    bankAccount.userId = userId;
    bankAccount.bankId = bankId;
    
    final docRef = await _firestore
        .collection('banks')
        .doc(bankId)
        .collection('accounts')
        .add(bankAccount.toMap());
        
    // Update the account with its new ID
    await docRef.update({'id': docRef.id});
  }

  // Get all accounts for a bank
  Stream<List<BankAccount>> getAccounts(String bankId) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('banks')
        .doc(bankId)
        .collection('accounts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;  // Include the document ID
              return BankAccount.fromMap(data);
            })
            .toList());
  }

  // Update an account
  Future<void> updateAccount(String bankId, String accountId, BankAccount bankAccount) async {
    await _firestore
        .collection('banks')
        .doc(bankId)
        .collection('accounts')
        .doc(accountId)
        .update(bankAccount.toMap());
  }

  // Delete an account
  Future<void> deleteAccount(String bankId, String accountId) async {
    await _firestore
        .collection('banks')
        .doc(bankId)
        .collection('accounts')
        .doc(accountId)
        .delete();
  }

  // Get accounts by type
  Stream<List<BankAccount>> getAccountsByType(String bankId, String accountType) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('banks')
        .doc(bankId)
        .collection('accounts')
        .where('accountType', isEqualTo: accountType)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;  // Include the document ID
              return BankAccount.fromMap(data);
            })
            .toList());
  }

  // Get total balance for an account type across all banks
  Future<double> getTotalBalanceByType(String accountType) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;
    
    final banksSnapshot = await _firestore.collection('banks').get();
    double totalBalance = 0;

    for (var bankDoc in banksSnapshot.docs) {
      final accountsSnapshot = await bankDoc.reference
          .collection('accounts')
          .where('accountType', isEqualTo: accountType)
          .where('userId', isEqualTo: userId)
          .get();

      for (var accountDoc in accountsSnapshot.docs) {
        totalBalance += accountDoc.data()['balance'] ?? 0;
      }
    }

    return totalBalance;
  }
}