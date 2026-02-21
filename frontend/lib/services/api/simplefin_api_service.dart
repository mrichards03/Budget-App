import 'base_api_service.dart';

class SimpleFinApiService extends BaseApiService {
  SimpleFinApiService({required super.baseUrl});

  Future<String> connectAccounts(String accessCode) async {
    final endpoint = '/api/simplefin/connect?access_code=$accessCode';
    final msg = await post(endpoint);
    return msg;
  }
}
