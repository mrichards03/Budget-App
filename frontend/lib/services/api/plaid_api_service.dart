import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'base_api_service.dart';

class PlaidApiService extends BaseApiService {
  PlaidApiService({required super.baseUrl});

  Future<List<dynamic>> getInstitutions() async {
    return await get('/api/plaid/institutions');
  }

  Future<String> connectAccounts(String accessCode) async {
    final endpoint = '/api/simplefin/connect?access_code=$accessCode';
    final msg = await post(endpoint);
    return msg;
  }

  Future<Map<String, dynamic>> syncTransactions(String itemId) async {
    return await post('/api/plaid/sync_transactions?item_id=$itemId');
  }

  Future<List<dynamic>> getInstitutionsList() async {
    return await get('/api/plaid/items');
  }
}
