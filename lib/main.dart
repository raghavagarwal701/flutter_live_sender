import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'My live stream app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final ApiVideoLiveStreamController _controller;
  final TextEditingController _streamKeyController = TextEditingController();
  bool _isStreaming = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _initializeLiveStream();
  }

  Future<void> _initializeLiveStream() async {
    _controller = createLiveStreamController();
    try {
      await _controller.initialize();
    } catch (e) {
      print('Failed to initialize controller: $e');
    }
  }

  ApiVideoLiveStreamController createLiveStreamController() {
    return ApiVideoLiveStreamController(
      initialAudioConfig: AudioConfig(),
      initialVideoConfig: VideoConfig(
      bitrate: 3000, // Adjust the bitrate as needed
      resolution: Resolution.RESOLUTION_1080,
      fps: 30, // Adjust the frame rate as needed
    ),
      onConnectionSuccess: () {
        print('Connection succeeded');
        setState(() {
          _isStreaming = true;
          _showPreview = true;
          // Lock to landscape when streaming starts
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft,
          ]);
        });
      },
      onConnectionFailed: (error) {
        print('Connection failed: $error');
        setState(() {
          _isStreaming = false;
        });
      },
      onDisconnection: () {
        print('Disconnected');
        setState(() {
          _isStreaming = false;
          _showPreview = false;
          // Revert to the default orientation when streaming stops
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        });
      },
    );
  }

  Future<void> _startStreaming() async {
    try {
      await _controller.startStreaming(
        streamKey: _streamKeyController.text,
        url: 'rtmp://35.154.14.164:1935/live',
      );
    } catch (e) {
      print('Failed to start streaming: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_showPreview)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _streamKeyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter Stream Key',
                  ),
                ),
              ),
            if (!_showPreview)
              ElevatedButton(
                onPressed: _isStreaming ? null : _startStreaming,
                child: const Text('Start Streaming'),
              ),
            if (_showPreview)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.9,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: ApiVideoCameraPreview(
                                    controller: _controller),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _streamKeyController.dispose();
    // Revert to the default orientation when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
