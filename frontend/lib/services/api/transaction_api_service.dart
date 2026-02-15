import 'base_api_service.dart';

class TransactionApiService extends BaseApiService {
  TransactionApiService({required super.baseUrl});

  Future<List<dynamic>> getTransactions({int skip = 0, int limit = 100}) async {
    return await get('/api/transactions/?skip=$skip&limit=$limit');
  }

  Future<void> categorizeTransaction(int transactionId, String category) async {
    await post(
        '/api/transactions/$transactionId/categorize?category=$category');
  }
}
