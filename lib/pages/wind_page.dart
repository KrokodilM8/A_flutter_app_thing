import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

import '../utils/wind_utils.dart';
import '../widgets/compass_painter.dart';

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
  bool _isLoading = false;
  double _deviceHeading = 0;
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
          _deviceHeading = heading;
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
      _isLoading = true;
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
        showError('Error: ${response.statusCode}');
      }
    } catch (e) {
      showError('Connection error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                  _isLoading ? null : () => fetchWindData(_cityController.text),
              child:
                  _isLoading
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
                          'Speed: $_windSpeed m/s',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Direction: ${getWindDirection(_windDeg)} ($_windDeg°)',
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
                                deviceHeading: _deviceHeading,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Phone orientation: ${_deviceHeading.toStringAsFixed(1)}°',
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
