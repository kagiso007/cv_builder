import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictiveTextService {
  final String apiUrl =
      "sk-proj-zIK80NsxgHVEhWvxlVNZT3BlbkFJkV0dfnBCyMHuEAxDhjdh";

  Future<String> getPredictiveText(String inputText) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"input": inputText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['predicted_text'];
    } else {
      throw Exception('Failed to load predictive text');
    }
  }
}
