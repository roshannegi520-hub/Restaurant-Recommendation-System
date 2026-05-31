import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RestaurantApiService {
  final String _apiHost = "local-business-data.p.rapidapi.com";

  Future<List<dynamic>> fetchRestaurants(String query) async {
    final apiKey = dotenv.env['RAPID_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("RapidAPI Key not found in .env");
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
        'https://$_apiHost/search?query=$encodedQuery&limit=5&language=en');

    final response = await http.get(url, headers: {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': _apiHost,
      'Content-Type': "application/json"
    });

    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      return decodedData['data'] ?? [];
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
