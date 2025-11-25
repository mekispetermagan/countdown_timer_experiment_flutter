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
  int _totalSeconds;
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

  set totalSeconds(int value) => _totalSeconds = value;

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
  final double fontSize;

  const CountdownLabel({
    required this.remainingSeconds,
    required this.color,
    required this.fontSize,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      0 != remainingSeconds
      ? remainingSeconds.toString().padLeft(2, '0')
      : "0",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      )
    );
  }
}

class CountdownTimer extends StatelessWidget {
  final CountdownStatus status;
  final double baseSize;
  const CountdownTimer({
    required this.status,
    required this.baseSize,
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
          size: baseSize*1.5,
          strokeWidth: baseSize*1.5,
          fgColor: bgRingTrack,
          bgColor: bgRingFill,
        ),
        // fg ring: arc with onContainer color
        CountdownRing(
          value: value,
          rotationAngle: rotationAngle,
          size: baseSize*3,
          strokeWidth: baseSize/4,
          fgColor: fgRingTrack,
          bgColor: fgRingFill,
        ),
        CountdownLabel(
          remainingSeconds: status.remainingSeconds,
          color: labelColor,
          fontSize: baseSize,
        ),
      ],
    );
  }
}

class Selector<T> extends StatelessWidget {
  final List<({String label, T value})> options;
  final T selected;
  final void Function(Set<T>) onSelectionChanged;
  const Selector({
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      selected: {selected},
      onSelectionChanged: onSelectionChanged,
      segments: [
        for (({String label, T value}) item in options)
          ButtonSegment<T>(
            value: item.value,
            label: Text(item.label),
            )
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
  double _baseSize = 30;
  int _totalSeconds = 45;
  bool _hasStarted = false;

  HomePageState();

  @override
  void initState() {
    super.initState();
    _manager = CountdownManager(
      totalSeconds: _totalSeconds,
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
    _hasStarted = true;
    _manager.reset(_timeMs);
    _manager.start(_timeMs);
  }

  void _onSelectSize(Set<double> sizeSet) {
    setState((){
      _baseSize = sizeSet.single;
    });
  }

  void _onSelectTotalSeconds(Set<int> set) {
    setState((){
      _totalSeconds = set.single;
      _manager.totalSeconds = _totalSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final CountdownStatus status = _manager.status;
    return Scaffold(
      appBar: AppBar(
        title: Text("Fancy Countdown timer"),
        foregroundColor: cs.onPrimaryContainer,
        backgroundColor: cs.primaryContainer,
        ),
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CountdownTimer(
              status: status,
              baseSize: _baseSize,
            ),
            Column(
              children: <Widget>[
                TextButton(
                  onPressed: _onRestart,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(cs.primaryContainer),
                    foregroundColor: WidgetStatePropertyAll(cs.onPrimaryContainer),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    child: Text(
                      _hasStarted ? "Restart" : "Start",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                  width: 0,
                ),
                Selector<double>(
                  options: [
                    (label: "S", value: 30),
                    (label: "M", value: 40),
                    (label: "L", value: 60),
                    (label: "XL", value: 80),
                  ],
                  selected: _baseSize,
                  onSelectionChanged: _onSelectSize,
                ),
                SizedBox(
                  height: 30,
                  width: 0,
                ),
                Selector<int>(
                  options: [
                    (label: "15s", value: 15),
                    (label: "30s", value: 30),
                    (label: "45s", value: 45),
                    (label: "60s", value: 60),
                  ],
                  selected: _totalSeconds,
                  onSelectionChanged: _onSelectTotalSeconds,
                ),
              ],
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
