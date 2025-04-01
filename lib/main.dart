import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WindApp());
}

class WindApp extends StatelessWidget {
  const WindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Vent',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const WindPage(),
    );
  }
}

class WindPage extends StatefulWidget {
  const WindPage({super.key});

  @override
  State<WindPage> createState() => _WindPageState();
}

class _WindPageState extends State<WindPage> {
  final TextEditingController _cityController = TextEditingController(
    text: 'Paris',
  );
  double? _windSpeed;
  int? _windDeg;
  bool _loading = false;
  double _deviceDirection = 0;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _magnetometerSubscription = magnetometerEvents.listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastUpdate).inMilliseconds > 200) {
        final angle = atan2(event.y, event.x) * (180 / pi);
        final heading = (angle + 360) % 360;
        setState(() {
          _deviceDirection = heading;
        });
        _lastUpdate = now;
      }
    });
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchWindData(String city) async {
    setState(() {
      _loading = true;
    });

    const apiKey = 'a3baa5aed122cb20874a1a1710ea7586';
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _windSpeed = data['wind']['speed']?.toDouble();
          _windDeg = data['wind']['deg']?.toInt();
        });
      } else {
        showError('Error : ${response.statusCode}');
      }
    } catch (e) {
      showError('Connection error');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String getWindDirection(int? deg) {
    if (deg == null) return '-';
    const directions = [
      'North',
      'North / North-Est',
      'North Est',
      'Est / North-Est',
      'Est',
      'Est / South-Est',
      'South / Est',
      'South / South-Est',
      'South',
      'South / South-West',
      'South / West',
      'West / South-West',
      'West',
      'West / North-West',
      'North / West',
      'North / North-West',
    ];
    return directions[((deg + 11.25) ~/ 22.5) % 16];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wind Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
              onSubmitted: fetchWindData,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  _loading ? null : () => fetchWindData(_cityController.text),
              child:
                  _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Get Wind Data'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_windSpeed != null && _windDeg != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Wind Speed: $_windSpeed m/s',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Wind Direction: ${getWindDirection(_windDeg)} ($_windDeg°)',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: SizedBox(
                            height: 220,
                            width: 220,
                            child: CustomPaint(
                              painter: CompassPainter(
                                windDeg: _windDeg!,
                                deviceOrientation: _deviceDirection,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Phone direction : ${_deviceDirection.toStringAsFixed(1)}°',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final int windDeg;
  final double deviceOrientation;

  CompassPainter({required this.windDeg, required this.deviceOrientation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    final paintNeedle =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paintCircle);

    final relativeAngle = ((windDeg - deviceOrientation) - 90) * pi / 180;
    final needleLength = radius * 0.9;

    final needleEnd = Offset(
      center.dx + needleLength * cos(relativeAngle),
      center.dy + needleLength * sin(relativeAngle),
    );

    canvas.drawLine(center, needleEnd, paintNeedle);
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.windDeg != windDeg ||
        oldDelegate.deviceOrientation != deviceOrientation;
  }
}
