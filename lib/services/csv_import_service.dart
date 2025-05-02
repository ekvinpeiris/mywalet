import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:intl/intl.dart'; // For date parsing

import '../controllers/account_controller.dart';
import '../controllers/bank_controller.dart';
import '../models/bank.dart';
import '../models/bank_account.dart';

class CsvImportResult {
  final int totalRows;
  final int importedCount;
  final int skippedDuplicateCount;
  final int skippedErrorCount;
  final List<String> errors;

  CsvImportResult({
    required this.totalRows,
    required this.importedCount,
    required this.skippedDuplicateCount,
    required this.skippedErrorCount,
    required this.errors,
  });
}

class CsvImportService {
  final AccountController _accountController = AccountController();
  final BankController _bankController = BankController();

  // Expected CSV Headers (case-insensitive check)
  final List<String> _expectedHeaders = [
    'bank name',
    'account number',
    'principal amount',
    'interest rate',
    'start date',
    'maturity date',
    'duration in months',
    'interest payout frequency',
  ];

  Future<CsvImportResult> importFixedDepositsFromCsv() async {
    int totalRows = 0;
    int importedCount = 0;
    int skippedDuplicateCount = 0;
    int skippedErrorCount = 0;
    List<String> errors = [];
    List<BankAccount> accountsToSave = [];

    try {
      // 1. Pick CSV File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        errors.add('File selection cancelled.');
        return CsvImportResult(
            totalRows: 0,
            importedCount: 0,
            skippedDuplicateCount: 0,
            skippedErrorCount: 0,
            errors: errors);
      }

      String? filePath = result.files.single.path;
      Uint8List? fileBytes = result.files.single.bytes;

      String csvString;
      if (fileBytes != null) {
        // Used for web or when bytes are available
        csvString = utf8.decode(fileBytes);
      } else if (filePath != null) {
        // Used for mobile/desktop
        final file = File(filePath);
        csvString = await file.readAsString();
      } else {
        errors.add('Could not read the selected file.');
        return CsvImportResult(
            totalRows: 0,
            importedCount: 0,
            skippedDuplicateCount: 0,
            skippedErrorCount: 1,
            errors: errors);
      }

      // 2. Parse CSV
      List<List<dynamic>> csvData =
          const CsvToListConverter(eol: '\n', fieldDelimiter: ',')
              .convert(csvString);

      if (csvData.isEmpty) {
        errors.add('CSV file is empty.');
        return CsvImportResult(
            totalRows: 0,
            importedCount: 0,
            skippedDuplicateCount: 0,
            skippedErrorCount: 1,
            errors: errors);
      }

      // 3. Validate Headers
      List<String> headers =
          csvData[0].map((h) => h.toString().toLowerCase().trim()).toList();
      Map<String, int> headerIndexMap = {};

      for (int i = 0; i < _expectedHeaders.length; i++) {
        int index = headers.indexOf(_expectedHeaders[i]);
        if (index == -1 && i < 3) { // Only first 3 are mandatory
           errors.add('Missing required header column: "${_expectedHeaders[i]}"');
           skippedErrorCount++; // Count header error as one general error
        } else if (index != -1) {
          headerIndexMap[_expectedHeaders[i]] = index;
        }
      }

       if (skippedErrorCount > 0) {
         return CsvImportResult(
             totalRows: csvData.length -1, // Exclude header row
             importedCount: 0,
             skippedDuplicateCount: 0,
             skippedErrorCount: skippedErrorCount + (csvData.length -1), // Count all rows as skipped due to header error
             errors: errors);
       }


      // 4. Fetch Existing Data (Banks and Accounts) for checks
      final List<Bank> existingBanks = await _bankController.getBanks().first;
      // We'll fetch accounts per bank inside the loop to avoid loading everything

      // 5. Process Rows
      totalRows = csvData.length - 1; // Exclude header row
      for (int i = 1; i < csvData.length; i++) {
        List<dynamic> row = csvData[i];
        int currentRowNum = i + 1; // User-friendly row number (1-based index + header)

        // Basic row length check
        if (row.length < headers.length) {
             errors.add('Row $currentRowNum: Incorrect number of columns. Expected ${headers.length}, got ${row.length}. Skipping.');
             skippedErrorCount++;
             continue;
        }

        String bankName = row[headerIndexMap['bank name']!].toString().trim();
        String accountNumber = row[headerIndexMap['account number']!].toString().trim();
        String principalAmountStr = row[headerIndexMap['principal amount']!].toString().trim();

        // --- Validation ---
        String? errorForRow;

        // Required fields check
        if (bankName.isEmpty) errorForRow = 'Bank Name is required.';
        if (accountNumber.isEmpty) errorForRow = 'Account Number is required.';
        if (principalAmountStr.isEmpty) errorForRow = 'Principal Amount is required.';

        // Bank Lookup
        Bank? foundBank;
        if (errorForRow == null) {
          try {
            foundBank = existingBanks.firstWhere(
              (b) => b.bankName.trim().toLowerCase() == bankName.toLowerCase(),
            );
          } catch (e) {
            errorForRow = 'Bank "$bankName" not found in the application.';
          }
        }

        // Principal Amount parsing
        double? principalAmount;
        if (errorForRow == null) {
          principalAmount = double.tryParse(principalAmountStr);
          if (principalAmount == null) {
            errorForRow = 'Invalid Principal Amount format: "$principalAmountStr".';
          } else if (principalAmount < 0) {
             errorForRow = 'Principal Amount cannot be negative.';
          }
        }

        // Duplicate Check (only if bank and account number are valid)
        if (errorForRow == null && foundBank?.id != null && accountNumber.isNotEmpty) {
           try {
                bool exists = await _accountController.checkAccountExists(foundBank!.id!, accountNumber);
                if (exists) {
                    // Skip duplicate, don't add to errors list, just increment counter
                    skippedDuplicateCount++;
                    continue; // Move to next row
                }
           } catch (e) {
               errorForRow = 'Error checking for duplicate account: $e';
           }
        }

        // --- Optional Fields Parsing (only if no errors so far) ---
        double? interestRate;
        DateTime? startDate;
        DateTime? maturityDate;
        int? durationInMonths;
        String? interestPayoutFrequency;

        if (errorForRow == null) {
            // Interest Rate
            if (headerIndexMap.containsKey('interest rate')) {
                String rateStr = row[headerIndexMap['interest rate']!].toString().trim();
                if (rateStr.isNotEmpty) {
                    interestRate = double.tryParse(rateStr);
                    if (interestRate == null) errorForRow = 'Invalid Interest Rate format: "$rateStr".';
                    else if (interestRate < 0) errorForRow = 'Interest Rate cannot be negative.';
                }
            }

            // Start Date (YYYY-MM-DD)
            if (errorForRow == null && headerIndexMap.containsKey('start date')) {
                String dateStr = row[headerIndexMap['start date']!].toString().trim();
                if (dateStr.isNotEmpty) {
                    try {
                        startDate = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
                    } catch (e) {
                        errorForRow = 'Invalid Start Date format: "$dateStr". Expected YYYY-MM-DD.';
                    }
                }
            }

            // Maturity Date (YYYY-MM-DD)
             if (errorForRow == null && headerIndexMap.containsKey('maturity date')) {
                String dateStr = row[headerIndexMap['maturity date']!].toString().trim();
                if (dateStr.isNotEmpty) {
                    try {
                        maturityDate = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
                    } catch (e) {
                        errorForRow = 'Invalid Maturity Date format: "$dateStr". Expected YYYY-MM-DD.';
                    }
                }
            }

            // Duration
            if (errorForRow == null && headerIndexMap.containsKey('duration in months')) {
                 String durationStr = row[headerIndexMap['duration in months']!].toString().trim();
                 if (durationStr.isNotEmpty) {
                     durationInMonths = int.tryParse(durationStr);
                     if (durationInMonths == null) errorForRow = 'Invalid Duration format: "$durationStr".';
                     else if (durationInMonths <= 0) errorForRow = 'Duration must be positive.';
                 }
            }

            // Interest Payout Frequency
            if (errorForRow == null && headerIndexMap.containsKey('interest payout frequency')) {
                String freqStr = row[headerIndexMap['interest payout frequency']!].toString().trim().toLowerCase();
                 if (freqStr.isNotEmpty) {
                     if (['on_maturity', 'monthly', 'annually'].contains(freqStr)) {
                         interestPayoutFrequency = freqStr;
                     } else {
                         errorForRow = 'Invalid Interest Payout Frequency: "$freqStr". Allowed: on_maturity, monthly, annually.';
                     }
                 }
            }
        }


        // --- Add to save list or record error ---
        if (errorForRow != null) {
          errors.add('Row $currentRowNum: $errorForRow Skipping.');
          skippedErrorCount++;
        } else {
          // Create BankAccount object
          accountsToSave.add(BankAccount(
            bankId: foundBank!.id!, // We know foundBank is not null here
            accountNumber: accountNumber,
            accountType: 'Fixed Deposit', // Hardcoded type
            balance: principalAmount!, // We know principalAmount is not null
            interestRate: interestRate,
            startDate: startDate,
            maturityDate: maturityDate,
            durationInMonths: durationInMonths,
            interestPayoutFrequency: interestPayoutFrequency,
            // userId will be set by the controller/service during save
          ));
        }
      }

      // 6. Save Valid Accounts (Batch write might be better for large files)
      if (accountsToSave.isNotEmpty) {
        // Assuming AccountController handles setting the userId
        // TODO: Consider adding a batch save method to AccountController
        for (var account in accountsToSave) {
          try {
            await _accountController.addAccount(account.bankId!, account);
            importedCount++;
          } catch (e) {
            errors.add('Error saving account ${account.accountNumber} for bank ${account.bankId}: $e');
            skippedErrorCount++; // Count save errors
          }
        }
      }
    } catch (e) {
      errors.add('An unexpected error occurred during import: ${e.toString()}');
      // Adjust counts if error happened mid-process
      skippedErrorCount = totalRows - importedCount - skippedDuplicateCount;
       if (skippedErrorCount < 0) skippedErrorCount = totalRows; // Ensure non-negative
    }

    return CsvImportResult(
      totalRows: totalRows,
      importedCount: importedCount,
      skippedDuplicateCount: skippedDuplicateCount,
      skippedErrorCount: skippedErrorCount,
      errors: errors,
    );
  }
}
