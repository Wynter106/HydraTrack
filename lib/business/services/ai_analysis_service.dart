import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/secrets.dart';

class AiAnalysisService {
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static Future<String> analyzeTodayHydration({
    required double currentOz,
    required double goalOz,
    required double caffeineMg,
    required double caffeineLimitMg,
    required int logCount,
    required int streak,
    required double weeklyAvgPercent,   // 0~100
    required String topDrink,           // most logged beverage name
    required String drinkingPattern,    // 'morning' | 'afternoon' | 'evening' | 'spread'
    required int uniqueDrinkTypes,
  }) async {
    final todayPercent = goalOz > 0 ? (currentOz / goalOz * 100).round() : 0;

    final prompt = '''
You are a hydration coach giving personalized feedback. Be friendly, specific, and encouraging.
Use the data below to give 2-3 sentences of insight — mention patterns, trends, or habits you notice.

Today:
- Hydration: ${currentOz.toStringAsFixed(1)} oz / ${goalOz.toStringAsFixed(1)} oz ($todayPercent% of goal)
- Caffeine: ${caffeineMg.toStringAsFixed(0)} mg / ${caffeineLimitMg.toStringAsFixed(0)} mg limit
- Drinks logged: $logCount
- Drinking pattern today: $drinkingPattern

Weekly:
- 7-day average goal completion: ${weeklyAvgPercent.toStringAsFixed(0)}%
- Current streak: $streak day(s)

Habits:
- Most consumed drink: $topDrink
- Unique drink types today: $uniqueDrinkTypes

Give actionable, specific advice based on patterns. Respond in English only. Keep it under 60 words.
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 150,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['choices']?[0]?['message']?['content'] as String?;
    if (text == null) throw Exception('Unexpected response: ${response.body}');
    return text.trim();
  }
}
