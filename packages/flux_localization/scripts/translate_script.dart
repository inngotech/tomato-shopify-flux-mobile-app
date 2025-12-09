// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TranslationScript {
  Map<String, String> config = {};
  String folder = '';
  String mainLang = '';
  String aiTranslate = '';

  Future<void> loadConfig() async {
    final envFile = File('.env');
    if (!await envFile.exists()) {
      print(
          '❌ .env file not found. Please copy env.example to .env and configure it.');
      exit(1);
    }

    final lines = await envFile.readAsLines();
    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        config[key] = value;
      }
    }

    folder = config['FOLDER'] ?? 'lib/src/l10n';
    mainLang = config['MAIN_LANG'] ?? 'en';
    aiTranslate = config['AI_TRANSLATE'] ?? 'gpt-4o';

    print('✅ Config loaded successfully');
    print('📁 Folder: $folder');
    print('🌐 Main language: $mainLang');
    print('🤖 AI service: $aiTranslate');
  }

  Future<List<String>> scanLanguages() async {
    final dir = Directory(folder);
    if (!await dir.exists()) {
      print('❌ Folder $folder not found');
      exit(1);
    }

    final languages = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.arb')) {
        final fileName = entity.path.split('/').last;
        final langCode =
            fileName.replaceAll('intl_', '').replaceAll('.arb', '');
        languages.add(langCode);
      }
    }

    languages.sort();
    print('✅ Found ${languages.length} languages: ${languages.join(', ')}');
    return languages;
  }

  Future<Map<String, dynamic>> loadLanguageFile(String langCode) async {
    final filePath = '$folder/intl_$langCode.arb';
    final file = File(filePath);

    if (!await file.exists()) {
      print('⚠️  Language file not found: $filePath');
      return {};
    }

    try {
      final content = await file.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error reading $filePath: $e');
      return {};
    }
  }

  Future<void> saveLanguageFile(
      String langCode, Map<String, dynamic> data) async {
    final filePath = '$folder/intl_$langCode.arb';
    final file = File(filePath);

    try {
      const encoder = JsonEncoder.withIndent('\t');
      final jsonString = encoder.convert(data);
      await file.writeAsString(jsonString);
      print('✅ Saved: $filePath');
    } catch (e) {
      print('❌ Error saving $filePath: $e');
    }
  }

  List<String> findMissingKeys(
      Map<String, dynamic> mainData, Map<String, dynamic> targetData) {
    final missingKeys = <String>[];

    for (final key in mainData.keys) {
      if (key.startsWith('@@')) continue; // Skip metadata keys
      if (!targetData.containsKey(key)) {
        missingKeys.add(key);
      }
    }

    return missingKeys;
  }

  String getLanguageName(String langCode) {
    final languageNames = {
      'am': 'Amharic',
      'ar': 'Arabic',
      'az': 'Azerbaijani',
      'bg': 'Bulgarian',
      'bn': 'Bengali',
      'bs': 'Bosnian',
      'ca': 'Catalan',
      'cs': 'Czech',
      'da': 'Danish',
      'de': 'German',
      'el': 'Greek',
      'en': 'English',
      'es': 'Spanish',
      'et': 'Estonian',
      'fa': 'Persian',
      'fi': 'Finnish',
      'fr': 'French',
      'he': 'Hebrew',
      'hi': 'Hindi',
      'hu': 'Hungarian',
      'id': 'Indonesian',
      'it': 'Italian',
      'ja': 'Japanese',
      'ka': 'Georgian',
      'kk': 'Kazakh',
      'km': 'Khmer',
      'kn': 'Kannada',
      'ko': 'Korean',
      'ku': 'Kurdish',
      'lo': 'Lao',
      'lt': 'Lithuanian',
      'mr': 'Marathi',
      'ms': 'Malay',
      'my': 'Burmese',
      'nl': 'Dutch',
      'no': 'Norwegian',
      'pl': 'Polish',
      'pt_BR': 'Portuguese (Brazil)',
      'pt_PT': 'Portuguese (Portugal)',
      'ro': 'Romanian',
      'ru': 'Russian',
      'si': 'Sinhala',
      'sk': 'Slovak',
      'sq': 'Albanian',
      'sr': 'Serbian',
      'sv': 'Swedish',
      'sw': 'Swahili',
      'ta': 'Tamil',
      'te': 'Telugu',
      'th': 'Thai',
      'ti': 'Tigrinya',
      'tr': 'Turkish',
      'uk': 'Ukrainian',
      'ur': 'Urdu',
      'uz': 'Uzbek',
      'vi': 'Vietnamese',
      'zh_CN': 'Chinese (Simplified)',
      'zh_TW': 'Chinese (Traditional)',
      'zh': 'Chinese',
    };

    return languageNames[langCode] ??
        ('${langCode.toUpperCase()}(this is language code)');
  }

  Future<Map<String, String>> translateTexts(List<String> keys,
      Map<String, dynamic> mainData, String targetLang) async {
    final translations = <String, String>{};

    if (keys.isEmpty) return translations;

    final languageName = getLanguageName(targetLang);

    // Split large batches into smaller chunks for better success rate
    const chunkSize = 20; // Process 20 keys at a time
    final chunks = <List<String>>[];

    for (var i = 0; i < keys.length; i += chunkSize) {
      final end = (i + chunkSize < keys.length) ? i + chunkSize : keys.length;
      chunks.add(keys.sublist(i, end));
    }

    print(
        '🔄 Translating ${keys.length} keys to $languageName in ${chunks.length} batch(es)...');

    for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final chunk = chunks[chunkIndex];
      final textsToTranslate =
          chunk.map((key) => mainData[key].toString()).toList();

      print(
          '  📦 Processing batch ${chunkIndex + 1}/${chunks.length} (${chunk.length} keys)...');

      try {
        final apiResponse =
            await callAI(textsToTranslate, targetLang, languageName);

        if (apiResponse != null && apiResponse.length == chunk.length) {
          for (var i = 0; i < chunk.length; i++) {
            translations[chunk[i]] = apiResponse[i];
          }
          print('  ✅ Batch ${chunkIndex + 1} completed');
        } else {
          print(
              '  ⚠️  Batch ${chunkIndex + 1} response count mismatch: expected ${chunk.length}, got ${apiResponse?.length ?? 0}');

          // Try to salvage partial results if possible
          if (apiResponse != null && apiResponse.isNotEmpty) {
            final maxIndex = apiResponse.length < chunk.length
                ? apiResponse.length
                : chunk.length;
            for (var i = 0; i < maxIndex; i++) {
              if (apiResponse[i].isNotEmpty) {
                translations[chunk[i]] = apiResponse[i];
              }
            }
            print(
                '  🔄 Salvaged $maxIndex translations from batch ${chunkIndex + 1}');
          }

          // Try individual translation for failed items
          await _retryFailedTranslations(chunk, mainData, targetLang,
              languageName, apiResponse, translations);
        }

        // Add delay between batches to avoid rate limiting
        if (chunkIndex < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('  ❌ Batch ${chunkIndex + 1} failed: $e');
        // Try individual translation for this batch
        await _retryFailedTranslations(
            chunk, mainData, targetLang, languageName, null, translations);
      }
    }

    print(
        '✅ Translation completed for $languageName: ${translations.length}/${keys.length} successful');
    return translations;
  }

  Future<void> _retryFailedTranslations(
    List<String> failedKeys,
    Map<String, dynamic> mainData,
    String targetLang,
    String languageName,
    List<String>? partialResponse,
    Map<String, String> translations,
  ) async {
    print('  🔄 Retrying failed translations individually...');

    var startIndex = partialResponse?.length ?? 0;
    final keysToRetry = failedKeys.skip(startIndex).toList();

    for (var i = 0; i < keysToRetry.length && i < 5; i++) {
      // Limit retry to 5 items
      final key = keysToRetry[i];
      final text = mainData[key].toString();

      try {
        final result = await callAI([text], targetLang, languageName);
        if (result != null && result.isNotEmpty && result[0].isNotEmpty) {
          translations[key] = result[0];
          print('  ✅ Individual retry successful for: $key');
        }

        // Small delay between individual retries
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('  ❌ Individual retry failed for $key: $e');
      }
    }
  }

  Future<List<String>?> callAI(
      List<String> texts, String targetLangCode, String targetLangName) async {
    try {
      switch (aiTranslate) {
        case 'openai':
          return await callOpenAI(texts, targetLangName);
        case 'gemini':
          return await callGemini(texts, targetLangName);
        case 'grok':
          return await callGrok(texts, targetLangName);
        default:
          print('❌ Unknown AI service: $aiTranslate');
          print('Available options: openai, gemini, grok');
          return null;
      }
    } catch (e) {
      print('❌ AI API call failed: $e');
      return null;
    }
  }

  Future<List<String>?> callOpenAI(
      List<String> texts, String targetLangName) async {
    final apiUrl = config['OPENAI_BASE_URL'];
    final apiKey = config['OPENAI_APIKEY'];
    final model = config['OPENAI_MODEL'] ?? 'gpt-4';

    if (apiUrl == null || apiKey == null) {
      print('❌ Missing OpenAI configuration');
      print('Required: OPENAI_BASE_URL, OPENAI_APIKEY');
      return null;
    }

    final prompt = createTranslationPrompt(texts, targetLangName);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional translator. Return only a JSON array of translated strings in the exact same order as provided, with no additional text or formatting.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      return parseTranslationResponse(content);
    } else {
      print('❌ OpenAI API error: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  Future<List<String>?> callGemini(
      List<String> texts, String targetLangName) async {
    final baseUrl = config['GEMINI_BASE_URL'];
    final apiKey = config['GEMINI_APIKEY'];
    final model = config['GEMINI_MODEL'];

    if (baseUrl == null || apiKey == null || model == null) {
      print('❌ Missing Gemini configuration');
      print('Required: GEMINI_BASE_URL, GEMINI_APIKEY, GEMINI_MODEL');
      return null;
    }

    final prompt = createTranslationPrompt(texts, targetLangName);
    final uri = Uri.parse('$baseUrl/$model:generateContent?key=$apiKey');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'You are a professional translator. Return only a JSON array of translated strings in the exact same order as provided, with no additional text or formatting.\n\n$prompt'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return parseTranslationResponse(content);
    } else {
      print('❌ Gemini API error: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  Future<List<String>?> callGrok(
      List<String> texts, String targetLangName) async {
    final apiUrl = config['GROK_BASE_URL'];
    final apiKey = config['GROK_APIKEY'];
    final model = config['GROK_MODEL'] ?? 'grok-beta';

    if (apiUrl == null || apiKey == null) {
      print('❌ Missing Grok configuration');
      print('Required: GROK_BASE_URL, GROK_APIKEY');
      return null;
    }

    final prompt = createTranslationPrompt(texts, targetLangName);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional translator. Return only a JSON array of translated strings in the exact same order as provided, with no additional text or formatting.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.3,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      return parseTranslationResponse(content);
    } else {
      print('❌ Grok API error: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  String createTranslationPrompt(List<String> texts, String targetLangName) {
    final textsJson = json.encode(texts);

    // Add specific instructions for certain languages
    var specificInstructions = '';
    if (targetLangName == 'Amharic') {
      specificInstructions = '''
- Use proper Amharic script (Ge'ez script)
- Follow Ethiopian localization conventions
- Use formal/polite language appropriate for apps
''';
    } else if (targetLangName == 'Arabic') {
      specificInstructions = '''
- Use Modern Standard Arabic
- Maintain right-to-left text flow
- Use appropriate formal language
''';
    } else if (targetLangName.contains('Chinese')) {
      specificInstructions = '''
- Use appropriate Chinese characters (Simplified or Traditional as specified)
- Follow Chinese app localization standards
''';
    }

    return '''
You are a professional translator specializing in mobile app localization.

Task: Translate the following English texts to $targetLangName.

Input (JSON array of English strings):
$textsJson

Requirements:
1. Return EXACTLY the same number of translations as input strings
2. Maintain the EXACT same order as the input
3. Preserve ALL placeholders unchanged: {variable}, {count}, {name}, {price}, etc.
4. Use natural, user-friendly language appropriate for mobile apps
5. Return ONLY a valid JSON array, no explanations or additional text
$specificInstructions

Output format: ["translation1", "translation2", "translation3", ...]

CRITICAL: Your response must be a valid JSON array with exactly ${texts.length} elements.
''';
  }

  String _safeDecodeUnicode(String content) {
    try {
      // Handle potential Unicode issues by re-encoding
      final bytes = utf8.encode(content);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      return content; // Return original if encoding fails
    }
  }

  List<String>? parseTranslationResponse(String content) {
    try {
      print('🔍 Parsing response (${content.length} chars)...');

      // Clean up the content and handle Unicode safely
      var cleanContent = _safeDecodeUnicode(content.trim());

      // Try manual JSON parser first for Unicode content
      final manualResult = ManualJsonParser.parseJsonArray(cleanContent);
      if (manualResult != null) {
        return manualResult;
      }

      // Try standard JSON parsing
      try {
        final decoded = json.decode(cleanContent) as List;
        final result = decoded.map((e) => e.toString().trim()).toList();
        print('✅ Successfully parsed ${result.length} translations (standard)');
        return result;
      } catch (e) {
        print('⚠️  Standard JSON parse failed: $e');
      }

      // Try to extract JSON array from the response using multiple patterns
      final patterns = [
        RegExp(r'\[[\s\S]*?\]'), // Most greedy pattern
        RegExp(r'\[.*?\]', dotAll: true), // Original pattern
        RegExp(r'```json\s*(\[[\s\S]*?\])\s*```'), // Code block pattern
        RegExp(r'```\s*(\[[\s\S]*?\])\s*```'), // Generic code block
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(cleanContent);
        if (match != null) {
          var jsonStr = match.group(1) ?? match.group(0)!;

          // Try manual parser first
          final manualPatternResult = ManualJsonParser.parseJsonArray(jsonStr);
          if (manualPatternResult != null) {
            return manualPatternResult;
          }

          // Try standard parser
          try {
            final decoded = json.decode(jsonStr) as List;
            final result = decoded.map((e) => e.toString().trim()).toList();
            print(
                '✅ Successfully parsed ${result.length} translations (pattern)');
            return result;
          } catch (e) {
            continue; // Try next pattern
          }
        }
      }

      // Last resort: try to extract individual quoted strings
      try {
        final stringMatches = RegExp(r'"([^"]*)"').allMatches(cleanContent);
        if (stringMatches.isNotEmpty) {
          final result = stringMatches.map((m) => m.group(1)!).toList();
          print(
              '⚠️  Extracted ${result.length} strings from response (regex fallback)');
          return result;
        }
      } catch (e) {
        print('⚠️  Regex fallback failed: $e');
      }

      print('❌ No valid JSON array found in response');
      return null;
    } catch (e) {
      print('❌ Failed to parse translation response: $e');
      print(
          'Response content preview: ${content.length > 500 ? '${content.substring(0, 500)}...' : content}');
      return null;
    }
  }

  Future<void> run() async {
    print('🚀 Starting translation script...\n');

    // Load configuration
    await loadConfig();

    // Scan languages
    final languages = await scanLanguages();

    // Load main language data
    print('\n📖 Loading main language ($mainLang)...');
    final mainData = await loadLanguageFile(mainLang);
    if (mainData.isEmpty) {
      print('❌ Failed to load main language file');
      exit(1);
    }

    final mainKeys =
        mainData.keys.where((key) => !key.startsWith('@@')).toList();
    print('✅ Main language has ${mainKeys.length} translation keys');

    // Process each language
    print('\n🔄 Processing languages...\n');

    for (final langCode in languages) {
      if (langCode == mainLang) continue;

      print('───────────────────────────────────');
      print('🌐 Processing: ${getLanguageName(langCode)} ($langCode)');

      final targetData = await loadLanguageFile(langCode);
      final missingKeys = findMissingKeys(mainData, targetData);

      if (missingKeys.isEmpty) {
        print('✅ No missing keys');
        continue;
      }

      print(
          '📝 Missing ${missingKeys.length} keys: ${missingKeys.take(5).join(', ')}${missingKeys.length > 5 ? '...' : ''}');

      // Translate missing keys
      final translations =
          await translateTexts(missingKeys, mainData, langCode);

      if (translations.isNotEmpty) {
        // Add translations to target data
        for (final key in translations.keys) {
          targetData[key] = translations[key];
        }

        // Save updated file
        await saveLanguageFile(langCode, targetData);
        print('✅ Added ${translations.length} translations');
      }

      print('');
    }

    print('🎉 Translation script completed!');
  }
}

Future<void> main() async {
  final script = TranslationScript();
  await script.run();
}

/// Manual JSON array parser for Unicode-heavy content
/// This bypasses Dart's built-in JSON decoder which has issues with some Unicode characters

class ManualJsonParser {
  static List<String>? parseJsonArray(String content) {
    try {
      print('🔧 Using manual JSON parser for Unicode content...');

      var cleanContent = content.trim();

      // Find the array boundaries
      var startIndex = cleanContent.indexOf('[');
      var endIndex = cleanContent.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
        print('❌ No valid JSON array boundaries found');
        return null;
      }

      // Extract the content between brackets
      var arrayContent = cleanContent.substring(startIndex + 1, endIndex);

      // Parse manually by finding quoted strings
      var results = <String>[];
      var inQuotes = false;
      var escaping = false;
      var currentString = StringBuffer();

      for (var i = 0; i < arrayContent.length; i++) {
        var char = arrayContent[i];

        if (escaping) {
          // Handle escaped characters
          if (char == '"' || char == '\\' || char == '/') {
            currentString.write(char);
          } else if (char == 'n') {
            currentString.write('\n');
          } else if (char == 't') {
            currentString.write('\t');
          } else if (char == 'r') {
            currentString.write('\r');
          } else {
            currentString.write(char);
          }
          escaping = false;
        } else if (char == '\\') {
          escaping = true;
        } else if (char == '"') {
          if (inQuotes) {
            // End of string
            results.add(currentString.toString());
            currentString.clear();
            inQuotes = false;
          } else {
            // Start of string
            inQuotes = true;
          }
        } else if (inQuotes) {
          // Inside quotes, add character to current string
          currentString.write(char);
        }
        // Outside quotes, ignore commas, spaces, etc.
      }

      print('✅ Manual parser extracted ${results.length} strings');
      return results;
    } catch (e) {
      print('❌ Manual parser failed: $e');
      return null;
    }
  }
}
