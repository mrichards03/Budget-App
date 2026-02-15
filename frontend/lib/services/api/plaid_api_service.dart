import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'base_api_service.dart';

class PlaidApiService extends BaseApiService {
  PlaidApiService({required super.baseUrl});

  Future<List<dynamic>> getInstitutions() async {
    return await get('/api/plaid/institutions');
  }

  Future<String> createLinkToken({String? itemId}) async {
    final endpoint = itemId != null
        ? '/api/plaid/create_link_token?item_id=$itemId'
        : '/api/plaid/create_link_token';

    final data = await post(endpoint);
    return data['link_token'];
  }

  Future<Map<String, dynamic>> exchangePublicToken(
      String publicToken, LinkInstitution? institution) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/plaid/exchange_public_token').replace(
        queryParameters: {
          'public_token': publicToken,
          'inst_id': institution?.id ?? '',
          'inst_name': institution?.name ?? '',
        },
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to exchange token');
    }
  }

  Future<Map<String, dynamic>> syncTransactions(String itemId) async {
    return await post('/api/plaid/sync_transactions?item_id=$itemId');
  }

  Future<List<dynamic>> getInstitutionsList() async {
    return await get('/api/plaid/items');
  }
}
