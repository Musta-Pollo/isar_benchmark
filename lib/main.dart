import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:isar_benchmark/runner.dart';
import 'package:path_provider/path_provider.dart';

import 'executor/executor.dart';
import 'ui/result_container.dart';

Future<String> getDeviceName() async {
  final info = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await info.androidInfo;
    return androidInfo.model ??
        androidInfo.product ??
        androidInfo.device ??
        'Android Device';
  } else if (Platform.isIOS) {
    final iosInfo = await info.iosInfo;
    return iosInfo.utsname.machine ?? iosInfo.model ?? 'iOS Device';
  } else if (Platform.isLinux) {
    final linuxInfo = await info.linuxInfo;
    return linuxInfo.prettyName;
  } else if (Platform.isMacOS) {
    final macOsInfo = await info.macOsInfo;
    return macOsInfo.model;
  } else if (Platform.isWindows) {
    return 'Windows Device';
  }
  return 'Unknown Device';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tempDir = await getTemporaryDirectory();
  final benchDir = Directory('${tempDir.path}/bench')
    ..createSync(recursive: true);

  final deviceName = await getDeviceName();
  runApp(App(directory: benchDir.path, deviceName: deviceName));
}

class App extends StatelessWidget {
  final String deviceName;
  final String directory;

  const App({
    Key? key,
    required this.directory,
    required this.deviceName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DB Benchmark',
      theme: FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xff97cbe1),
          primaryContainer: Color(0xff97cbe1),
          secondary: Color(0xff296d8a),
          secondaryContainer: Color(0xff296d8a),
          tertiary: Color(0xff8da5af),
          tertiaryContainer: Color(0xff8da5af),
          appBarColor: Color(0xff296d8a),
          error: Color(0xffb00020),
        ),
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 20,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(
          defaultRadius: 18.0,
          thinBorderWidth: 1.0,
          bottomSheetRadius: 27.0,
          inputDecoratorBorderType: FlexInputBorderType.underline,
          fabUseShape: true,
          fabRadius: 24.0,
          popupMenuRadius: 12.0,
          dialogRadius: 27.0,
          timePickerDialogRadius: 27.0,
          bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
          useTertiary: true,
        ),
        tones: FlexTones.jolly(Brightness.light),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        // To use the playground font, add GoogleFonts package and uncomment
        // fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xff97cbe1),
          primaryContainer: Color(0xff97cbe1),
          secondary: Color(0xff296d8a),
          secondaryContainer: Color(0xff296d8a),
          tertiary: Color(0xff8da5af),
          tertiaryContainer: Color(0xff8da5af),
          appBarColor: Color(0xff296d8a),
          error: Color(0xffb00020),
        ),
        surfaceMode: FlexSurfaceMode.highSurfaceLowScaffold,
        blendLevel: 15,
        appBarOpacity: 0.80,
        subThemesData: const FlexSubThemesData(
          defaultRadius: 18.0,
          thinBorderWidth: 1.0,
          bottomSheetRadius: 27.0,
          inputDecoratorBorderType: FlexInputBorderType.underline,
          fabUseShape: true,
          fabRadius: 24.0,
          popupMenuRadius: 12.0,
          dialogRadius: 27.0,
          timePickerDialogRadius: 27.0,
          appBarBackgroundSchemeColor: SchemeColor.surface,
          bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
          useTertiary: true,
        ),
        tones: FlexTones.jolly(Brightness.dark),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        // To use the playground font, add GoogleFonts package and uncomment
        // fontFamily: GoogleFonts.nunito().fontFamily,
      ),
// If you do not have a themeMode switch, uncomment this line
// to let the device system mode control the theme mode:
      themeMode: ThemeMode.dark,

      home: Scaffold(
        body: Center(
          child: BenchmarkArea(
            deviceName: deviceName,
            directory: directory,
          ),
        ),
      ),
    );
  }
}

class BenchmarkArea extends StatefulWidget {
  final String deviceName;
  final String directory;

  const BenchmarkArea({
    Key? key,
    required this.directory,
    required this.deviceName,
  }) : super(key: key);

  @override
  State<BenchmarkArea> createState() => _BenchmarkAreaState();
}

class _BenchmarkAreaState extends State<BenchmarkArea> {
  var numberOfRounds = 4;
  var numberOfProjects = 200;
  late final runner = BenchmarkRunner(widget.directory, numberOfRounds);
  final results = <Database, RunnerResult>{};

  var benchmark = Benchmark.values[0];
  var bigObjects = true;
  var running = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Benchmarks"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Benchmark>(
                          value: benchmark,
                          decoration: const InputDecoration(
                            label: Text('Benchmark'),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (var benchmark in Benchmark.values)
                              DropdownMenuItem(
                                value: benchmark,
                                child: Text(
                                  benchmark.name,
                                  softWrap: true,
                                ),
                              )
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                benchmark = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: running ? null : run,
                        child: const Text('LET\'S GO!'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 1,
                    child: results.isNotEmpty
                        ? ResultContainer(
                            deviceName: widget.deviceName,
                            results: results.values.toList(),
                            objectCount: numberOfProjects,
                            roundsCount: numberOfRounds,
                          )
                        : const Center(
                            child: Text('No results yet.'),
                          ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: running || results.isEmpty
                        ? null
                        : ResultContainer.shareAsImage,
                    child: const Text('Share'),
                  ),
                ],
              ),
              const SizedBox(
                height: 46,
              ),
              Text(
                "Settings",
                style: Theme.of(context).textTheme.headline3,
              ),
              const SizedBox(
                height: 27,
              ),
              Text(
                "Number Of Rounds",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 18,
              ),
              ToggleButtons(
                isSelected: [
                  numberOfRounds == 2,
                  numberOfRounds == 4,
                  numberOfRounds == 6,
                  numberOfRounds == 8,
                  numberOfRounds == 10,
                ],
                onPressed: (index) {
                  setState(() {
                    index += 1;
                    numberOfRounds = index * 2;
                  });
                },
                children: const [
                  Text('2'),
                  Text('4'),
                  Text('6'),
                  Text('8'),
                  Text('10'),
                ],
              ),
              const SizedBox(
                height: 27,
              ),
              Text(
                "Number Of Projects",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 18,
              ),
              ToggleButtons(
                isSelected: [
                  numberOfProjects == 200,
                  numberOfProjects == 400,
                  numberOfProjects == 600,
                  numberOfProjects == 800,
                  numberOfProjects == 1000,
                  numberOfProjects == 10000,
                ],
                onPressed: (index) {
                  setState(() {
                    index += 1;
                    numberOfProjects = index * 2 * 100;
                    if (index == 6) {
                      numberOfProjects = 10000;
                    }
                  });
                },
                children: const [
                  Text('200'),
                  Text('400'),
                  Text('600'),
                  Text('800'),
                  Text('1k'),
                  Text('10k'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void run() {
    setState(() {
      running = true;
      results.clear();
    });

    final stream = runner.runBenchmark(benchmark, numberOfProjects, bigObjects);
    stream.listen((event) {
      setState(() {
        results[event.database] = event;
      });
    }).onDone(() {
      setState(() {
        running = false;
      });
    });
  }
}
