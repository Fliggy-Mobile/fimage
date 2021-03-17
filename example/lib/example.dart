import 'package:fimage/fimage.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'main.dart';

extension on FGifController {
  bool getBool(key) {
    return get(key, def: false);
  }
}

class GifExample extends StatefulWidget {
  @override
  _GifExampleState createState() => _GifExampleState();
}

class _GifExampleState extends State<GifExample> with TickerProviderStateMixin {
  FGifController controller1;
  FGifController controller2;
  final listLen = 5;
  List<FGifController> controllers;
  List<bool> showed;
  List<String> gifList = [
    // 'https://media2.giphy.com/media/gdwf3hCno7Uouwdjmf/giphy.gif',
    'https://4.bp.blogspot.com/-V4gs2Jb3v5I/XvFWpHH1RHI/AAAAAAAM8gw/8QE2vfEVBI82W74yuUcP20zL6CQ4m1xsgCLcBGAsYHQ/s1600/AS0006889_09.gif',
    'https://i.pinimg.com/originals/a6/f1/bd/a6f1bd65f2a51ce01381b83889e6cf84.gif',
    'https://2.bp.blogspot.com/-raIPXM2cLsA/WDvmi2LchuI/AAAAAAAD6hQ/F-jkwPT1Rmkyye23FUTUjI_rC14mSy5uACLcB/s1600/AS001542_14.gif',
    'https://2.bp.blogspot.com/-oKedFMlP5lo/Wl3mM94ZI_I/AAAAAAAIrKc/443pd8i9b2sq3CynbLoQeDUQfTP9K5LoACLcBGAs/s1600/AS003549_01.gif',
  ];

  String apng = 'https://im7.ezgif.com/tmp/ezgif-7-c8221bda75ad.png';
  String gif = 'https://media2.giphy.com/media/gdwf3hCno7Uouwdjmf/giphy.gif';

  @override
  void initState() {
    super.initState();
    controller1 = FGifController(vsync: this);
    controller2 = FGifController(vsync: this);
    controllers = List(listLen);
    showed = List(listLen)..fillRange(0, listLen, false);
  }

  @override
  void dispose() {
    controller1?.dispose();
    controller2?.dispose();
    controllers?.forEach((element) {
      element?.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FGifImage Example'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            MyApp.restartApp(context);
          },
          child: Text('replay'),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 40,
            ),
            FImage(
              image: NetworkImage(gif),
              width: 150,
              height: 150,
              controller: controller2,
              onFetchCompleted: () {
                if (!controller2.isCompleted) {
                  controller2.forward();
                }
              },
              frameBuilder: (BuildContext context, Widget child,
                  int currentFrame, int totalFrame) {
                return child;
              },
            ),
            SizedBox(
              height: 20,
            ),
            Text('gif play when fetchCompleted'),
            SizedBox(
              height: 20,
            ),
            // FImage(
            //   image: NetworkImage(apng),
            //   width: 150,
            //   height: 150,
            //   controller: controller1,
            //   onFetchCompleted: () {
            //     if (!controller1.isCompleted) {
            //       controller1.forward();
            //     }
            //   },
            //   frameBuilder: (BuildContext context, Widget child,
            //       int currentFrame, int totalFrame) {
            //     return child;
            //   },
            // ),
            SizedBox(
              height: 40,
            ),
            Text('gif play only once when fetchCompleted and visibility>0.9'),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return _buildGifItem(index);
                },
                itemCount: listLen,
                separatorBuilder: (context, index) {
                  return SizedBox(
                    width: 15,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGifItem(int index) {
    if (controllers[index] == null) {
      print('new FGifController $index');
      controllers[index] = FGifController(vsync: this);
    }
    controllers[index].stop();
    return VisibilityDetector(
      key: Key('gifVisibilityDetector-${controllers[index]}-$index'),
      child: FImage(
        image: NetworkImage(gifList[index % gifList.length]),
        width: 150,
        height: 150,
        controller: controllers[index],
        onFetchCompleted: () {
          controllers[index].set("onFetchCompleted", true);
          if (showed[index]) {
            controllers[index].forward(from: 1);
            return;
          }
          if (controllers[index].getBool("onVisible")) {
            controllers[index].forward(from: 0);
            showed[index] = true;
          }
        },
        frameBuilder: (BuildContext context, Widget child, int currentFrame,
            int totalFrame) {
          return child;
        },
      ),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.9) {
          controllers[index].set("onVisible", true);
          if (controllers[index].getBool("onFetchCompleted") &&
              !controllers[index].isAnimating &&
              !controllers[index].isCompleted) {
            controllers[index].forward(from: 0);
            showed[index] = true;
          }
        }
      },
    );
  }
}
