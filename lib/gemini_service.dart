import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  Future<String> generateSmartTag(
      String restaurantName, String userQuery) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return "Smart Tag Unavailable";

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    final prompt = '''
      You are a smart local guide AI. 
      The user searched for: "$userQuery". 
      The restaurant is: "$restaurantName". 
      Write a punchy, 5 to 8 word tag explaining exactly why this place is a good match for their search.
      Do not use quotation marks.
    ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "Highly Recommended";
    } catch (e) {
      return "Great Match";
    }
  }
}
