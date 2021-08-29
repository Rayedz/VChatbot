import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart' as sst;
import 'package:text_to_speech/text_to_speech.dart' as tts;
import 'package:ibm_watson_assistant/ibm_watson_assistant.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Colors.cyan[300],
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  late sst.SpeechToText _speechToText;
  late tts.TextToSpeech _textToSpeech;
  late IbmWatsonAssistant assistant;
  String? _sessionId;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _text = 'Press the button and start speaking';
  String lastError = '';

  @override
  void initState() {
    super.initState();
    _speechToText = sst.SpeechToText();
    _textToSpeech = tts.TextToSpeech();
    _initAssistant();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Voice Chatbot'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
          animate: _isListening,
          glowColor: Colors.cyanAccent,
          endRadius: 75.0,
          duration: const Duration(milliseconds: 800),
          repeatPauseDuration: const Duration(milliseconds: 0),
          repeat: true,
          child: FloatingActionButton(
            onPressed: _listen,
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            backgroundColor: Colors.cyan[500],
          ),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
            child: Column(children: [
              Text(
                _text,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
              ),
              Lottie.asset('assets/talking-robot.json', animate: _isSpeaking),
            ])));
  }

  void _initAssistant() async {
    assistant = IbmWatsonAssistant(IbmWatsonAssistantAuth(
      assistantId: '3c10cc45-9b7f-4bcf-9eb4-917678f6e896',
      url:
          'https://api.eu-gb.assistant.watson.cloud.ibm.com/instances/77bba580-d75d-4215-94e8-3b1adceff8ce',
      apikey: 'B8EkeuEsYma8vPNrfOr54BEQYvH_z_om5bKNRApLMIkd',
    ));

    _sessionId = await assistant.createSession();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = false;
      print('before $available');
      available = await _speechToText.initialize(
          onStatus: (val) => print('onState: $val'),
          onError: (val) => print('onError: $val'),
          debugLogging: true);
      print('after $available');
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
            onResult: (val) => setState(() {
                  _text = val.recognizedWords;
                }));
      }
    } else {
      _speechToText.stop();
      final assistantRes =
          await assistant.sendInput(_text, sessionId: _sessionId);
      setState(() => _isListening = false);
      _textToSpeech.setVolume(1);
      setState(() => _isSpeaking = true);
      print('fa');
      await _textToSpeech.speak(assistantRes.responseText ?? "");
      print('da');
      setState(() => _isSpeaking = false);
    }
  }
}
