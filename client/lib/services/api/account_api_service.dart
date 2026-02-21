import 'base_api_service.dart';

class AccountApiService extends BaseApiService {
  AccountApiService({required super.baseUrl});

  Future<List<dynamic>> getAccounts() async {
    return await get('/api/accounts');
  }

  Future<double> getTotalBalance() async {
    final data = await get('/api/accounts/total_balance');
    return data['total_balance'].toDouble();
  }
}
