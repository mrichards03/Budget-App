import 'base_api_service.dart';

class TransactionApiService extends BaseApiService {
  TransactionApiService({required super.baseUrl});

  Future<List<dynamic>> getTransactions({
    int skip = 0,
    int limit = 100,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String url = '/api/transactions/?skip=$skip&limit=$limit';

    if (startDate != null) {
      final startStr = startDate.toIso8601String().split('T')[0];
      url += '&start_date=$startStr';
    }

    if (endDate != null) {
      final endStr = endDate.toIso8601String().split('T')[0];
      url += '&end_date=$endStr';
    }

    return await get(url);
  }

  Future<void> categorizeTransaction(
      int transactionId, int subcategoryId) async {
    await post(
      '/api/transactions/$transactionId/categorize',
      body: {
        'subcategory_id': subcategoryId,
      },
    );
  }

  /// Create or replace splits for a transaction.
  /// `splits` should be a list of maps: { 'subcategory_id': int, 'amount': double, 'memo': String? }
  Future<dynamic> setTransactionSplits(
    int transactionId,
    List<Map<String, dynamic>> splits, {
    bool replaceExisting = true,
  }) async {
    final body = {
      'splits': splits,
      'replace_existing': replaceExisting,
    };

    return await post('/api/transactions/$transactionId/splits', body: body);
  }

}
