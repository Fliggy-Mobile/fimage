<p align="center">
  <a href="https://github.com/Fliggy-Android-Team">
    <img width="200" src="https://gw.alicdn.com/tfs/TB1a288sxD1gK0jSZFKXXcJrVXa-360-360.png">
  </a>
</p>

<h1 align="center">FImage</h1>


<div align="center">

<p>FImage实现加载多种图片资源</p>

<p>支持dart:ui可解码静态图片<strong>&动态图片播放控制</strong> ，图片第一帧回调解码回调，全部帧解码完成回调，缓存管理，预加载到缓存，支持网络和本地图片加载</p>

<p><strong>主理人：<a href="https://github.com/zhongyiqwer">钟易</a>(<a href="zhongyi.zjx@alibaba-inc.com">zhongyi.zjx@alibaba-inc.com</a>)</strong></p>

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

**[English](https://github.com/Fliggy-Mobile/fimage) | 简体中文**

> 感觉还不错？请投出您的 **Star** 吧 🥰 ！

# ✨ 特性

- 支持对dart:ui可解码图片播放的控制

- 支持自定义扩展解码

- 支持静态&动态图片

- 支持图片进行预加载到缓存中

- 支持网络&本地&内存图片加载

- 提供缓存，支持自定义大小

- 提供丰富回调（图片加载完成，每一帧展示回调）

- 代码量少&包小，方便改造&扩展

# 🛠 使用指南
对于FImage中，开发者可以轻松的使用
```dart
///创建控制iamge的controller
var controller = FImageController(vsync: this);

///在build中创建FImage
Widget image = FImage(
  image: NetworkImage(imageUrl),
  width: 150,
  height: 150,
  controller: controller,
  onFetchCompleted: (allImageInfo) {
    if(allImageInfo.frameCount == 0) {
      ///加载解析图片出错
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

## ⚙️ 参数

### FImageController

|参数|类型|必要|默认值|说明|
|---|---|:---:|---|---|
|vsync|TickerProvider|true|null|提供帧定时回调|
|value|double|false|0.0|动画初始值|
|duration|Duration|false|null|反向动画时间|
|duration|Duration|false|null|动画时间(默认使用动图解析出来的动画时间)|
|animationBehavior|AnimationBehavior|false|AnimationBehavior.normal|动画行为|
|repetitionCount|int|false|-2|动画循环次数（不设置默认-2为动图解析出来次数）|

### FImage

|参数|类型|必要|默认值|说明|
|---|---|:---:|---|---|
|imageProvider|ImageProvider|true|null|图片加载器|
|controller|FImageController|false|null|动画控制器|
|semanticLabel|String|false|null|图片描述|
|excludeFromSemantics|bool|false|false|是否从语义上排除该图片|
|width|double|false|null|图片宽度|
|height|double|false|null|图片高度|
|onFetchCompleted|FOnFetchCompleted|false|null|图片加载完成回调|
|color|Color|false|null|图片的前景色|
|colorBlendMode|BlendMode|false|null|color的混合模式|
|fit|BoxFit|false|null|图片的显示模式|
|alignment|AlignmentGeometry|false|Alignment.center|图片的对齐方式|
|repeat|ImageRepeat|false|ImageRepeat.noRepeat|图片的重复方式|
|centerSlice|Rect|false|null|切片拉伸|
|matchTextDirection|bool|false|false|是否与文本方向一致|
|frameBuilder|FImageFrameBuilder|false|null|图片每一帧的回调|
|needRepaintBoundary|bool|false|true|图片是否使用单独图层|
|decoder|Decoder|false|GifDecoder|图片解码器|

## 📺 使用示例

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


加载静态图片或者不控制动图
```dart
Widget image= FImage(
     imageProvider: NetworkImage(imageUrl),
     width: 150,
     height: 150,
     );           
```

*完整示例代码见example/lib/example.dart文件*。


# 😃 如何使用？

在项目 `pubspec.yaml` 文件中添加依赖：

## 🌐 pub 依赖方式

```
dependencies:
  fimage: ^<版本号>
```

> ⚠️ 注意，请到 [**pub**](//todo) 获取 **FImage** 最新版本号

## 🖥 git 依赖方式

```
dependencies:
  fimage:
    git:
      url: 'git@github.com:Fliggy-Android-Team/fimage.git'
      ref: '<分支号 或 tag>'
```


> ⚠️ 注意，分支号 或 tag 请以 [**FImage**](https://github.com/Fliggy-Mobile/fimage) 官方项目为准。


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


### 感觉还不错？请投出您的 [**Star**](https://github.com/Fliggy-Mobile/fimage) 吧 🥰 ！

# How to run Demo project?
    1.clone project to local

    2.Enter the project example directory and run the following command
    
        flutter create .

    3.Run the demo in example
    