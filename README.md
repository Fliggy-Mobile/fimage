<p align="center">
  <a href="https://github.com/Fliggy-Mobile">
    <img width="200" src="https://gw.alicdn.com/tfs/TB1a288sxD1gK0jSZFKXXcJrVXa-360-360.png">
  </a>
</p>

<h1 align="center">FImage</h1>


<div align="center">

<p>FImage realize loading a variety of image resources</p>

<p>Support dart:ui can decode static pictures <strong>&dynamic picture playback control</strong>, picture first frame callback decoding callback, all frame decoding completion callback, cache management, preload to cache, support network and local picture loading</p>

<p><strong>Author：<a href="https://github.com/zhongyiqwer">ZhongYi</a>(<a href="zhongyi.zjx@alibaba-inc.com">zhongyi.zjx@alibaba-inc.com</a>)</strong></p>

<p>

<a href="https://pub.dev/packages/fimage#-readme-tab-">
    <img height="20" src="https://img.shields.io/badge/Version-0.0.1-important.svg">
</a>


<a href="https://github.com/Fliggy-Android-Team/fimage">
    <img height="20" src="https://img.shields.io/badge/Build-passing-brightgreen.svg">
</a>


<a href="https://github.com/Fliggy-Android-Team">
    <img height="20" src="https://img.shields.io/badge/Team-FAT-ffc900.svg">
</a>

<a href="https://www.dartcn.com/">
    <img height="20" src="https://img.shields.io/badge/Language-Dart-blue.svg">
</a>

<a href="https://pub.dev/documentation/fimage/latest/fimage/fimage-library.html">
    <img height="20" src="https://img.shields.io/badge/API-done-yellowgreen.svg">
</a>

<a href="http://www.apache.org/licenses/LICENSE-2.0.txt">
   <img height="20" src="https://img.shields.io/badge/License-Apache--2.0-blueviolet.svg">
</a>

<p>
<p>

<img height="400" src="https://img.alicdn.com/imgextra/i1/O1CN01DPGbVc227U2EPc7Vp_!!6000000007073-1-tps-400-228.gif">

</div>

**English | [简体中文](https://github.com/Fliggy-Mobile/fimage/blob/master/README_CN.md)**

> Like it? Please cast your **Star** 🥰 ！

# ✨ Features

- Support the control of dart:ui decodable picture playback

- Support custom extension decoding

- Support static & dynamic pictures

- Support pictures to be preloaded into the cache

- Support network & local & memory image loading

- Provide cache, support custom size

- Provide rich callbacks (the picture is loaded and the callback is displayed for each frame)

- Less code & small package, convenient for modification

# 🛠 Guide
In FImage, developers can easily use it.
```dart
///Create a controller to control the image
var controller = FImageController(vsync: this);

///Create FImage in build
Widget image = FImage(
  image: NetworkImage(imageUrl),
  width: 150,
  height: 150,
  controller: controller,
  onFetchCompleted: (allImageInfo) {
    if(allImageInfo.frameCount == 0) {
      ///load iamge error
    } else if (!controller1.isCompleted) {
      controller1.forward();
    }
  },
  frameBuilder: (BuildContext context, Widget child,
      int currentFrame, int totalFrame) {
    return child;
  },
);
```

## ⚙️ Parameters

### FImageController

|Param|Type|Necessary|Default|desc|
|---|---|:---:|---|---|
|vsync|TickerProvider|true|null|Provide frame timing callback|
|value|double|false|0.0|Animation initial value|
|duration|Duration|false|null|Reverse animation time|
|duration|Duration|false|null|Animation time (animation time parsed by image will be used)|
|animationBehavior|AnimationBehavior|false|AnimationBehavior.normal|Animation behavior|
|repetitionCount|int|false|-2|Animation loop times（default is -2 when can not resolved）|

### FImage

|Param|Type|Necessary|Default|desc|
|---|---|:---:|---|---|
|imageProvider|ImageProvider|true|null|image loader|
|controller|FImageController|true|null|Animation controller|
|semanticLabel|String|false|null|picture description|
|excludeFromSemantics|bool|false|false|Whether to exclude the image semantically|
|width|double|false|null|picture width|
|height|double|false|null|picture height|
|onFetchCompleted|VoidCallback|false|null|image loading complete callback|
|color|Color|false|null|Foreground of the picture|
|colorBlendMode|BlendMode|false|null|color blending mode|
|fit|BoxFit|false|null|Picture display mode|
|alignment|AlignmentGeometry|false|Alignment.center|Alignment of the picture|
|repeat|ImageRepeat|false|ImageRepeat.noRepeat|How the picture is repeated|
|centerSlice|Rect|false|null|Slice stretch|
|matchTextDirection|bool|false|false|Is it consistent with the text direction|
|frameBuilder|FImageFrameBuilder|false|null|Callback for each frame of image|
|needRepaintBoundary|bool|false|true|Whether the image uses a separate layer|
|decoder|Decoder|false|GifDecoder|Picture decoder|

## 📺 Example

<img height="400" src="https://img.alicdn.com/imgextra/i3/O1CN016THoFV1NZyQfgFvde_!!6000000001585-1-tps-400-228.gif">

```dart
   Widget _buildGifItem(int index) {
    if (controllers[index] == null) {
      print('new FImageController $index');
      controllers[index] = FImageController(vsync: this, repetitionCount: 0);
    }
    controllers[index].stop();
    return VisibilityDetector(
      key: Key('gifVisibilityDetector-${controllers[index]}-$index'),
      child: FImage(
        imageProvider: NetworkImage(gifList[index % gifList.length]),
        width: 150,
        height: 150,
        controller: controllers[index],
        onFetchCompleted: (_) {
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
            controllers[index].forward();
            showed[index] = true;
          }
        } else {
          controllers[index].stop();
        }
      },
    );
  }
```

Load static pictures or do not control dynamic pictures
```dart
Widget image= FImage(
     imageProvider: NetworkImage(imageUrl),
     width: 150,
     height: 150,
     );           
```

*The complete code can be found in the example/lib/example.dart file*。


# 😃 How to use？

Add dependencies in the project `pubspec.yaml` file:

## 🌐 pub dependency

```
dependencies:
  fimage: ^<version number>
```

> ⚠️ Attention，please go to  [**pub**](https://pub.dev/packages/fimage) to get the latest version number of **FImage**

## 🖥 git dependency

```
dependencies:
  fimage:
    git:
      url: 'git@github.com:Fliggy-Mobile/fimage.git'
      ref: '<Branch number or tag number>'
```


> ⚠️ Attention，please refer to [**FImage**](https://github.com/Fliggy-Mobile/fimage) official project for branch number or tag.。


# 💡 License

```
Copyright 2020-present Fliggy Android Team <alitrip_android@list.alibaba-inc.com>.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at following link.

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

```


### Like it? Please cast your  [**Star**](https://github.com/Fliggy-Mobile/fimage)  🥰 ！

# How to run Demo project?
    1.clone project to local

    2.Enter the project example directory and run the following command
 
        flutter create .

    3.Run the demo in example