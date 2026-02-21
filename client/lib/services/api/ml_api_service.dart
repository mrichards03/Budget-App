import 'base_api_service.dart';

class MlApiService extends BaseApiService {
  MlApiService({required super.baseUrl});

  Future<Map<String, dynamic>> predictCategory({
    required String transactionText,
    required double amount,
    String? merchantName,
  }) async {
    final queryParams = {
      'transaction_text': transactionText,
      'amount': amount.toString(),
      if (merchantName != null) 'merchant_name': merchantName,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await post('/api/ml/predict?$queryString');
  }

  Future<Map<String, dynamic>> trainModels() async {
    return await post('/api/ml/train', body: {});
  }

  Future<Map<String, dynamic>> retrainModel() async {
    return await post('/api/ml/retrain', body: {});
  }

  Future<Map<String, dynamic>> autoCategorizeAll() async {
    return await post('/api/ml/auto_categorize', body: {});
  }

  Future<Map<String, dynamic>> getModelStatus() async {
    return await get('/api/ml/models/status');
  }

  Future<List<dynamic>> batchPredict(List<int> transactionIds) async {
    return await post('/api/ml/batch_predict',
        body: {'transaction_ids': transactionIds});
  }
}
