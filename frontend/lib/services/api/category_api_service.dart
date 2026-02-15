import 'base_api_service.dart';

class CategoryApiService extends BaseApiService {
  CategoryApiService({required super.baseUrl});

  Future<List<dynamic>> getCategories() async {
    return await get('/api/categories');
  }
}
