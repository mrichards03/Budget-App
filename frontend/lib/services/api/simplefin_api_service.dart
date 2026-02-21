import 'base_api_service.dart';
import 'api_result.dart';

class SimpleFinApiService extends BaseApiService {
  SimpleFinApiService({required super.baseUrl});

  Future<ApiResult<String>> connectAccounts(String accessCode) async {
    final endpoint = '/api/simplefin/connect?access_code=$accessCode';
    try {
      final response = await post(endpoint);
      return ApiResult<String>.fromJson(response);
    } catch (e) {
      return ApiResult.error(e.toString());
    }
  }

  Future<ApiResult<bool>> doesAccessExist() async {
    const endpoint = '/api/simplefin/access-exists';
    try {
      final response = await get(endpoint);
      return ApiResult<bool>.fromJson(response);
    } catch (e) {
      return ApiResult<bool>.error(e.toString());
    }
  }

  Future<ApiResult<String>> sync() async {
    const endpoint = '/api/simplefin/sync';
    try {
      final response = await post(endpoint);
      return ApiResult<String>.fromJson(response);
    } catch (e) {
      return ApiResult.error(e.toString());
    }
  }
}
