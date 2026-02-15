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
    return await post('/api/ml/train');
  }
}
