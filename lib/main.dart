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

class CountdownRing extends StatelessWidget {
  final double value;
  final double rotationAngle;
  final double size;
  final double strokeWidth;
  final Color fgColor;
  final Color bgColor;
  const CountdownRing({
    required this.value,
    required this.rotationAngle,
    required this.size,
    required this.strokeWidth,
    required this.fgColor,
    required this.bgColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: rotationAngle,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: strokeWidth,
          color: fgColor,
          backgroundColor: bgColor,
        ),
      ),
    );
  }
}

class CountdownLabel extends StatelessWidget {
  final int remainingSeconds;
  final Color color;

  const CountdownLabel({
    required this.remainingSeconds,
    required this.color,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      0 != remainingSeconds
      ? remainingSeconds.toString().padLeft(2, '0')
      : "0",
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: color,
      )
    );
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
    final double rotationAngle = -status.remainingSeconds / 30 * pi;
    final double value = status.isRunning
      ? status.withinSecondMs / 1000
      : 1;

    final bool danger = status.isInDangerZone;
    final bool filling = status.isRunning && status.remainingSeconds % 2 == 0;

    final Color bgRingTrack;
    final Color bgRingFill;
    final Color fgRingTrack;
    final Color fgRingFill;
    switch ((danger, filling)) {
      case (true, true) : {
        bgRingTrack = cs.surface;
        bgRingFill = cs.errorContainer;
        fgRingTrack = cs.surface;
        fgRingFill = cs.onErrorContainer;
      }
      case (true, false) : {
        bgRingTrack = cs.errorContainer;
        bgRingFill = cs.surface;
        fgRingTrack = cs.onErrorContainer;
        fgRingFill = cs.surface;
      }
      case (false, true) : {
        bgRingTrack = cs.surface;
        bgRingFill = cs.secondaryContainer;
        fgRingTrack = cs.surface;
        fgRingFill = cs.onSecondaryContainer;
      }
      case (false, false) : {
        bgRingTrack = cs.secondaryContainer;
        bgRingFill = cs.surface;
        fgRingTrack = cs.onSecondaryContainer;
        fgRingFill = cs.surface;
      }
    }
    Color labelColor = status.isInDangerZone
      ? cs.onSecondaryContainer
      : cs.onErrorContainer;

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // bg ring: sector with container color
        CountdownRing(
          value: value,
          rotationAngle: rotationAngle,
          size: 48,
          strokeWidth: 48,
          fgColor: bgRingTrack,
          bgColor: bgRingFill,
        ),
        // fg ring: arc with onContainer color
        CountdownRing(
          value: value,
          rotationAngle: rotationAngle,
          size: 96,
          strokeWidth: 6,
          fgColor: fgRingTrack,
          bgColor: fgRingFill,
        ),
        CountdownLabel(
          remainingSeconds: status.remainingSeconds,
          color: labelColor,
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
      totalSeconds: 15,
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
