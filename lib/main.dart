import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:tpia/pages/first_page.dart';
import 'package:tpia/pages/paperpage.dart';
import 'package:bar/bar.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  runApp(MyApp());
  doWhenWindowReady(() {
    var initialSize = Size(1500, 800);
    appWindow.size = initialSize;
    appWindow.minSize = initialSize;
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: MaterialApp(
                title: 'Flutter Demo',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                ),
                home: FirstPage()),
          ),
        ],
      );
}
