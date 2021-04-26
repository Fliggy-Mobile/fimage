import 'package:flutter/material.dart';

import 'example.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static restartApp(BuildContext context) {
    var state = context.findAncestorStateOfType<_MyAppState>();
    state.restartApp();
  }
}

class _MyAppState extends State<MyApp> {
  Key key = UniqueKey();

  restartApp() {
    this.setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      child: GifExample(),
    );
  }
}
