
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:image_picker/image_picker.dart';

// class CattleVisionHomePage extends StatefulWidget {
//   const CattleVisionHomePage({super.key});

//   @override
//   State<CattleVisionHomePage> createState() => _CattleVisionHomePageState();
// }

// class _CattleVisionHomePageState extends State<CattleVisionHomePage> {
//   static const _geminiApiKey = 'YOUR_GEMINI_API_KEY';
//   File? _imageFile;
//   bool _isLoading = false;
//   Map<String, dynamic>? _results;
//   String _errorMessage = '';
//   late FlutterTts _flutterTts;
//   String _currentLanguage = 'en-IN';

//   @override
//   void initState() {
//     super.initState();
//     _flutterTts = FlutterTts();
//     _setTtsProperties();
//   }

//   Future<void> _setTtsProperties() async {
//     await _flutterTts.setLanguage(_currentLanguage);
//     await _flutterTts.setSpeechRate(0.5);
//     await _flutterTts.setVolume(1.0);
//   }

//   Future<void> _changeLanguage(String langCode) async {
//     setState(() {
//       _currentLanguage = langCode;
//       _setTtsProperties();
//     });
//   }

//   @override
//   void dispose() {
//     _flutterTts.stop();
//     super.dispose();
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final picker = ImagePicker();
//       final pickedFile = await picker.pickImage(source: source);
//       if (pickedFile != null) {
//         setState(() {
//           _imageFile = File(pickedFile.path);
//           _results = null;
//           _errorMessage = '';
//           _flutterTts.stop();
//         });
//       }
//     } catch (e) {
//       setState(() => _errorMessage = 'Failed to pick image: $e');
//     }
//   }

//   Future<void> _analyzeImage() async {
//     if (_imageFile == null) {
//       _showSnackBar('Please select an image first.');
//       return;
//     }
//     if (_geminiApiKey.isEmpty || _geminiApiKey == 'AIzaSyD9o3ixqYAsGTHXfauFOki-_1O4dPlTmt8') {
//       _showSnackBar('API key is not configured.');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _results = null;
//       _errorMessage = '';
//     });

//     try {
//       final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: _geminiApiKey);
//       final imageBytes = await _imageFile!.readAsBytes();
//       final prompt = Content.multi([
//         TextPart("""
// Analyze this image of a cattle. Respond ONLY with a single, complete JSON object.
// The JSON object should have two top-level keys: "breedAnalysis" and "healthAnalysis".

// For "breedAnalysis", include:
// 1. "isCrossbreed": a boolean indicating if it's likely a crossbreed.
// 2. "suggestions": an array of objects. Each object should have:
//    - "name": the suggested breed name.
//    - "confidence": a number (0.0 to 1.0) indicating confidence.
//    - "reason": a string explaining the reason for the suggestion.

// For "healthAnalysis", include:
// 1. An array of objects. Each object should have:
//    - "issue": a string describing the health issue (e.g., "Lameness", "Skin Lesion").
//    - "location": a string indicating the body part (e.g., "Right hind leg").
//    - "alert": a string with a severity level (e.g., "High", "Medium", "Low").
//    - "recommendation": a string with advice on what to do.

// If no health issues are found, the "healthAnalysis" array should be empty.
// """),
//         DataPart('image/jpeg', imageBytes),
//       ]);

//       final response = await model.generateContent([prompt]).timeout(const Duration(seconds: 30));
//       final jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
//       final Map<String, dynamic> apiResults = json.decode(jsonString);
//       setState(() => _results = apiResults);
//       _speakResults(apiResults);
//       _showResultsSheet();
//     } on TimeoutException {
//       setState(() => _errorMessage = 'Request timed out. Please try again.');
//       _showSnackBar('Analysis request timed out.');
//     } catch (e) {
//       setState(() => _errorMessage = 'Error during analysis: $e');
//       _showSnackBar('Error during analysis.');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red.shade600,
//       ),
//     );
//     _flutterTts.speak(message);
//   }

//   void _speakResults(Map<String, dynamic> results) async {
//     String ttsText = '';
//     final breedAnalysis = results['breedAnalysis'] as Map<String, dynamic>?;
//     final healthAnalysis = results['healthAnalysis'] as List<dynamic>?;

//     if (_currentLanguage == 'hi-IN') {
//       ttsText = 'विश्लेषण पूरा हो गया। ';
//     } else {
//       ttsText = 'Analysis complete. ';
//     }
//     await _flutterTts.speak(ttsText);
//   }

//   void _showResultsSheet() {
//     if (_results == null) return;
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => _buildResultSheet(),
//     );
//   }

//   Widget _buildResultSheet() {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.7,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//       ),
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//               height: 5,
//               width: 50,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2.5),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildResultCard(
//             title: 'Breed Suggestions',
//             icon: Icons.grass,
//             color: Colors.green.shade700,
//             content: _buildBreedAnalysisContent(),
//           ),
//           const SizedBox(height: 16),
//           _buildResultCard(
//             title: 'Health Alerts',
//             icon: Icons.medical_services,
//             color: Colors.red.shade600,
//             content: _buildHealthAnalysisContent(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBreedAnalysisContent() {
//     final breedAnalysis = _results!['breedAnalysis'] as Map<String, dynamic>;
//     final isCrossbreed = breedAnalysis['isCrossbreed'] as bool? ?? false;
//     final suggestions = breedAnalysis['suggestions'] as List<dynamic>? ?? [];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Status: ${isCrossbreed ? 'Crossbreed' : 'Purebred'}',
//           style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: isCrossbreed ? Colors.orange : Colors.green),
//         ),
//         const SizedBox(height: 8),
//         if (suggestions.isEmpty)
//           const Text('No breed suggestions found.',
//               style: TextStyle(fontStyle: FontStyle.italic)),
//         ...suggestions.map((s) => _buildSuggestionItem(s)),
//       ],
//     );
//   }

//   Widget _buildSuggestionItem(Map<String, dynamic> suggestion) {
//     final name = suggestion['name'] as String? ?? 'Unknown';
//     final confidence = suggestion['confidence'] as num? ?? 0;
//     final reason = suggestion['reason'] as String? ?? 'No reason provided.';

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         '$name - ${(confidence * 100).toStringAsFixed(1)}% | $reason',
//         style: const TextStyle(fontSize: 14),
//       ),
//     );
//   }

//   Widget _buildHealthAnalysisContent() {
//     final healthAnalysis = _results!['healthAnalysis'] as List<dynamic>? ?? [];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (healthAnalysis.isEmpty)
//           const Text(
//             'No significant health issues detected.',
//             style: TextStyle(fontStyle: FontStyle.italic),
//           ),
//         ...healthAnalysis.map((h) => _buildHealthIssueItem(h)),
//       ],
//     );
//   }

//   Widget _buildHealthIssueItem(Map<String, dynamic> issue) {
//     final issueName = issue['issue'] as String? ?? 'Unknown Issue';
//     final location = issue['location'] as String? ?? 'N/A';
//     final alert = issue['alert'] as String? ?? 'N/A';
//     final recommendation = issue['recommendation'] as String? ?? 'No recommendation provided.';
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '• $issueName ($location) - $alert',
//             style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//           ),
//           Text(
//             'Recommendation: $recommendation',
//             style: const TextStyle(fontSize: 12),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultCard({
//     required String title,
//     required IconData icon,
//     required Color color,
//     required Widget content,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 6))
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color),
//               const SizedBox(width: 10),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//           const Divider(),
//           content,
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     const themeColor = Color(0xFF5A8D3F);
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: themeColor,
//         elevation: 0,
//         title: const Text(
//           "CattleVision",
//           style: TextStyle(color: Colors.white),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildLanguageSelector(),
//             const SizedBox(height: 20),
//             Expanded(
//               child: _buildImageContainer(),
//             ),
//             const SizedBox(height: 20),
//             _buildAnalyzeButton(themeColor),
//             if (_errorMessage.isNotEmpty) ...[
//               const SizedBox(height: 16),
//               _buildErrorDisplay(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLanguageSelector() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: CupertinoSegmentedControl<String>(
//         children: const {
//           'en-IN': Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
//           ),
//           'hi-IN': Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text('हिंदी', style: TextStyle(fontWeight: FontWeight.bold)),
//           ),
//         },
//         onValueChanged: _changeLanguage,
//         groupValue: _currentLanguage,
//         selectedColor: const Color(0xFF5A8D3F),
//         unselectedColor: Colors.grey.shade200,
//         borderColor: Colors.transparent,
//       ),
//     );
//   }

//   Widget _buildImageContainer() {
//     return GestureDetector(
//       onTap: () => _showImageSourceActionSheet(),
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
//         ),
//         child: _imageFile == null
//             ? Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.image, size: 120, color: Colors.grey.shade300),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'Tap to select or capture image',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               )
//             : ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.file(
//                   _imageFile!,
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildAnalyzeButton(Color themeColor) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         icon: _isLoading
//             ? const SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//               )
//             : const Icon(Icons.search),
//         label: Text(_isLoading ? "Analyzing..." : "Analyze with AI"),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: themeColor,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//         ),
//         onPressed: _isLoading ? null : _analyzeImage,
//       ),
//     );
//   }

//   Widget _buildErrorDisplay() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.red.shade100,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Text(
//         _errorMessage,
//         style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Future<void> _showImageSourceActionSheet() async {
//     await showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: <Widget>[
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Photo Gallery'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 _pickImage(ImageSource.gallery);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Camera'),
//               onTap: () {
//                 Navigator.of(context).pop();
//                 _pickImage(ImageSource.camera);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class CattleVisionHomePage extends StatefulWidget {
  const CattleVisionHomePage({super.key});

  @override
  State<CattleVisionHomePage> createState() => _CattleVisionHomePageState();
}

class _CattleVisionHomePageState extends State<CattleVisionHomePage> {
final _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _results;
  String _errorMessage = '';
  late FlutterTts _flutterTts;
  String _currentLanguage = 'en-IN';

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _setTtsProperties();
  }

  Future<void> _setTtsProperties() async {
    await _flutterTts.setLanguage(_currentLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _changeLanguage(String langCode) async {
    setState(() {
      _currentLanguage = langCode;
      _setTtsProperties();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _results = null;
          _errorMessage = '';
          _flutterTts.stop();
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) {
      _showSnackBar('Please select an image first.');
      return;
    }
    if (_geminiApiKey.isEmpty || _geminiApiKey == 'AIzaSyCbg3y_tpMCvSRc7aOpC3LNr7CzHGpr_C4') {
      _showSnackBar('API key is not configured.');
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
      _errorMessage = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey);
      final imageBytes = await _imageFile!.readAsBytes();
      final prompt = Content.multi([
        TextPart("""
Analyze this image of a cattle. Respond ONLY with a single, complete JSON object.
The JSON object should have two top-level keys: "breedAnalysis" and "healthAnalysis".

For "breedAnalysis", include:
1. "isCrossbreed": a boolean indicating if it's likely a crossbreed.
2. "suggestions": an array of objects. Each object should have:
  - "name": the suggested breed name.
  - "confidence": a number (0.0 to 1.0) indicating confidence.
  - "reason": a string explaining the reason for the suggestion.

For "healthAnalysis", include:
1. An array of objects. Each object should have:
  - "issue": a string describing the health issue (e.g., "Lameness", "Skin Lesion").
  - "location": a string indicating the body part (e.g., "Right hind leg").
  - "alert": a string with a severity level (e.g., "High", "Medium", "Low").
  - "recommendation": a string with advice on what to do.

If no health issues are found, the "healthAnalysis" array should be empty.
"""),
        DataPart('image/jpeg', imageBytes),
      ]);

      final response = await model.generateContent([prompt]).timeout(const Duration(seconds: 30));
      final jsonString = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> apiResults = json.decode(jsonString);
      setState(() => _results = apiResults);
      _speakResults(apiResults);
      _showResultsSheet();
    } on TimeoutException {
      setState(() => _errorMessage = 'Request timed out. Please try again.');
      _showSnackBar('Analysis request timed out.');
    } catch (e) {
      setState(() => _errorMessage = 'Error during analysis: $e');
      _showSnackBar('Error during analysis.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal.shade700,
      ),
    );
    _flutterTts.speak(message);
  }

  void _speakResults(Map<String, dynamic> results) async {
    String ttsText = '';
    final breedAnalysis = results['breedAnalysis'] as Map<String, dynamic>?;
    final healthAnalysis = results['healthAnalysis'] as List<dynamic>?;

    if (breedAnalysis != null) {
      if (_currentLanguage == 'hi-IN') {
        ttsText += 'पशु की नस्ल का विश्लेषण। ';
      } else {
        ttsText += 'Cattle breed analysis. ';
      }
      final isCrossbreed = breedAnalysis['isCrossbreed'] as bool? ?? false;
      if (isCrossbreed) {
        if (_currentLanguage == 'hi-IN') {
          ttsText += 'यह एक संकर नस्ल लगती है। ';
        } else {
          ttsText += 'It appears to be a crossbreed. ';
        }
      } else {
        if (_currentLanguage == 'hi-IN') {
          ttsText += 'यह एक शुद्ध नस्ल लगती है। ';
        } else {
          ttsText += 'It appears to be a purebred. ';
        }
      }
      final suggestions = breedAnalysis['suggestions'] as List<dynamic>? ?? [];
      for (final s in suggestions) {
        final name = s['name'] as String? ?? 'Unknown';
        final confidence = (s['confidence'] as num? ?? 0) * 100;
        if (_currentLanguage == 'hi-IN') {
          ttsText += 'संभावित नस्ल $name, आत्मविश्वास ${confidence.toStringAsFixed(0)} प्रतिशत। ';
        } else {
          ttsText += 'Suggested breed $name with ${confidence.toStringAsFixed(0)} percent confidence. ';
        }
      }
    }

    if (healthAnalysis != null && healthAnalysis.isNotEmpty) {
      if (_currentLanguage == 'hi-IN') {
        ttsText += 'स्वास्थ्य संबंधी चेतावनियाँ। ';
      } else {
        ttsText += 'Health alerts detected. ';
      }
      for (final h in healthAnalysis) {
        final issue = h['issue'] as String? ?? 'Unknown Issue';
        final location = h['location'] as String? ?? 'N/A';
        final alert = h['alert'] as String? ?? 'N/A';
        final recommendation = h['recommendation'] as String? ?? 'No recommendation.';
        if (_currentLanguage == 'hi-IN') {
          ttsText += '$location पर $issue का पता चला है, चेतावनी स्तर $alert। सलाह: $recommendation। ';
        } else {
          ttsText += 'Issue: $issue detected at $location, alert level $alert. Recommendation: $recommendation. ';
        }
      }
    } else {
      if (_currentLanguage == 'hi-IN') {
        ttsText += 'कोई महत्वपूर्ण स्वास्थ्य समस्या नहीं पाई गई। ';
      } else {
        ttsText += 'No significant health issues detected. ';
      }
    }

    await _flutterTts.speak(ttsText);
  }

  void _showResultsSheet() {
    if (_results == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildResultSheet(),
    );
  }

  Widget _buildResultSheet() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildResultCard(
              title: 'Breed Suggestions',
              icon: Icons.grass,
              color: Colors.green.shade700,
              content: _buildBreedAnalysisContent(),
            ),
            const SizedBox(height: 16),
            _buildResultCard(
              title: 'Health Alerts',
              icon: Icons.medical_services,
              color: Colors.red.shade600,
              content: _buildHealthAnalysisContent(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedAnalysisContent() {
    final breedAnalysis = _results!['breedAnalysis'] as Map<String, dynamic>;
    final isCrossbreed = breedAnalysis['isCrossbreed'] as bool? ?? false;
    final suggestions = breedAnalysis['suggestions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status: ${isCrossbreed ? 'Crossbreed' : 'Purebred'}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCrossbreed ? Colors.orange : Colors.green),
        ),
        const SizedBox(height: 8),
        if (suggestions.isEmpty)
          const Text('No breed suggestions found.',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ...suggestions.map((s) => _buildSuggestionItem(s)),
      ],
    );
  }

  Widget _buildSuggestionItem(Map<String, dynamic> suggestion) {
    final name = suggestion['name'] as String? ?? 'Unknown';
    final confidence = suggestion['confidence'] as num? ?? 0;
    final reason = suggestion['reason'] as String? ?? 'No reason provided.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$name - ${(confidence * 100).toStringAsFixed(1)}% | $reason',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildHealthAnalysisContent() {
    final healthAnalysis = _results!['healthAnalysis'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (healthAnalysis.isEmpty)
          const Text(
            'No significant health issues detected.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ...healthAnalysis.map((h) => _buildHealthIssueItem(h)),
      ],
    );
  }

  Widget _buildHealthIssueItem(Map<String, dynamic> issue) {
    final issueName = issue['issue'] as String? ?? 'Unknown Issue';
    final location = issue['location'] as String? ?? 'N/A';
    final alert = issue['alert'] as String? ?? 'N/A';
    final recommendation = issue['recommendation'] as String? ?? 'No recommendation provided.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $issueName ($location) - $alert',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          Text(
            'Recommendation: $recommendation',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Divider(),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF5A8D3F);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "CattleVision",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLanguageSelector(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _buildImageContainer(),
                  ),
                  const SizedBox(height: 20),
                  _buildAnalyzeButton(Colors.teal),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildErrorDisplay(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white54),
      ),
      child: CupertinoSegmentedControl<String>(
        children: const {
          'en-IN': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('English', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          'hi-IN': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('हिंदी', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        },
        onValueChanged: _changeLanguage,
        groupValue: _currentLanguage,
        selectedColor: Colors.teal,
        unselectedColor: Colors.transparent,
        borderColor: Colors.transparent,
        pressedColor: Colors.teal.withOpacity(0.5),
      ),
    );
  }

  Widget _buildImageContainer() {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: _imageFile == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 120, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              'Tap to select or capture image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ],
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(Color themeColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Icon(Icons.search,color: Colors.white,),
        label: Text(_isLoading ? "Analyzing..." : "Analyze with AI",style: const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),),
        
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: _isLoading ? null : _analyzeImage,
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _errorMessage,
        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _showImageSourceActionSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}