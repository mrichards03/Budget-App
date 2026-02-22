import 'package:budget_app/models/account.dart';
import 'package:budget_app/services/api/api_result.dart';

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

  Future<ApiResult> updateType(String id, AccountType newType) async {
    final data = await post(
      '/api/accounts/$id/updateType',
      body: {
        'new_type': newType.index,
      });
    return ApiResult.fromJson(data);
  }
}
