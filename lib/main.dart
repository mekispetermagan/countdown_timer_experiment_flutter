import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';

class CountdownStatus {
  final int remainingSeconds;
  final int withinSecondMs;
  final bool isInDangerZone;
  final bool isRunning;
  const CountdownStatus({
    required this.remainingSeconds,
    required this.withinSecondMs,
    required this.isInDangerZone,
    required this.isRunning,
  });
}

class CountdownManager {
  final int _totalSeconds;
  final int _dangerZoneSeconds;
  late int _startingMs;
  int _elapsedMs = 0;
  bool _isRunning = false;

  CountdownManager({
    required int totalSeconds,
    required int dangerZoneSeconds,
  })
    : assert(0 < totalSeconds, "totalSeconds should be positive: $totalSeconds"),
      assert(0 <= dangerZoneSeconds, "dangerZoneSeconds shouldn't be negative: $dangerZoneSeconds"),
      assert(
        dangerZoneSeconds < totalSeconds,
        "dangerZoneSeconds should be smaller than totalSeconds: $dangerZoneSeconds vs $totalSeconds"
      ),
      _totalSeconds = totalSeconds,
      _dangerZoneSeconds = dangerZoneSeconds;

  CountdownStatus get status {
    final int elapsedSeconds = _elapsedMs ~/ 1000;
    final int remainingSeconds = max(_totalSeconds - elapsedSeconds, 0);
    final int withinSecondMs = _elapsedMs % 1000;
    final bool isInDangerZone = remainingSeconds < _dangerZoneSeconds;
    return CountdownStatus(
      remainingSeconds: remainingSeconds,
      withinSecondMs: withinSecondMs,
      isInDangerZone: isInDangerZone,
      isRunning: _isRunning,
    );
  }

  void start(int tickerMs) {
    _isRunning = true;
    _startingMs = tickerMs - _elapsedMs;
  }

  void pause(int tickerMs) {
    update(tickerMs);
    _isRunning = false;
  }

  void update(int tickerMs) {
    if (_isRunning) {
      _elapsedMs = tickerMs - _startingMs;
      final int elapsedSeconds = _elapsedMs ~/ 1000;
      if (_totalSeconds <= elapsedSeconds) {_isRunning = false;}
    }
  }

  void reset(int tickerMs) {
    _startingMs = tickerMs;
    _elapsedMs = 0;
    _isRunning = false;
  }
}

class CountdownTimer extends StatelessWidget {
  final CountdownStatus status;
  const CountdownTimer({
    required this.status,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int phase = 0 < status.remainingSeconds
      ? status.remainingSeconds % 2
      : 1;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          width: 45,
          height: 45,
          child: Transform.rotate(
            angle: status.remainingSeconds / 30 * pi,
            child: CircularProgressIndicator(
              value: status.withinSecondMs / 1000,
              strokeWidth: 45,
              color: status.isInDangerZone
                ? phase == 1 ? cs.secondaryContainer : cs.surface
                : phase == 1 ? cs.errorContainer : cs.surface,
              backgroundColor: status.isInDangerZone
                ? phase == 1 ? cs.surface : cs.secondaryContainer
                : phase == 1 ? cs.surface : cs.errorContainer,
            ),
          ),
        ),
        SizedBox(
          width: 90,
          height: 90,
          child: Transform.rotate(
            angle: status.remainingSeconds / 30 * pi,
            child: CircularProgressIndicator(
              value: status.withinSecondMs / 1000,
              strokeWidth: 6,
              color: status.isInDangerZone
                ? phase == 1 ? cs.onSecondaryContainer : cs.surface
                : phase == 1 ? cs.onErrorContainer : cs.surface,
              backgroundColor: status.isInDangerZone
                ? phase == 1 ? cs.surface : cs.onSecondaryContainer
                : phase == 1 ? cs.surface : cs.onErrorContainer,
            ),
          ),
        ),
        Text(
          0 != status.remainingSeconds
          ? status.remainingSeconds.toString().padLeft(2, '0')
          : "0",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: status.isInDangerZone
              ? cs.onSecondaryContainer
              : cs.onErrorContainer,
          )
        ),
      ],
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage>
  with SingleTickerProviderStateMixin {
  int _timeMs = 0;
  late Ticker _ticker;
  late final CountdownManager _manager;
  HomePageState();

  @override
  void initState() {
    super.initState();
    _manager = CountdownManager(
      totalSeconds: 60,
      dangerZoneSeconds: 10);
    _ticker = createTicker((elapsed) {
      setState(() {
        _timeMs = elapsed.inMilliseconds;
        _manager.update(_timeMs);
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onRestart() {
    _manager.reset(_timeMs);
    _manager.start(_timeMs);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final CountdownStatus status = _manager.status;
    return Scaffold(
      appBar: AppBar(title: Text("Countdown timer")),
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CountdownTimer(status: status),
            TextButton(
              onPressed: _onRestart,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(cs.primaryContainer),
                foregroundColor: WidgetStatePropertyAll(cs.onPrimaryContainer),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Text(
                  "Restart",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
              ),
            ),
          ],
        ),
      )
    );
  }
}

void main() {
  runApp(App());
}
