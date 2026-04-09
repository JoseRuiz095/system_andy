import 'package:http/http.dart' as http;
import 'package:system_andy/core/constants/app_constants.dart';

class ApiService {
  final http.Client client;
  ApiService({required this.client});

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/$endpoint');
    return await client.get(url);
  }

  // Otros métodos: post, put, delete...
}
