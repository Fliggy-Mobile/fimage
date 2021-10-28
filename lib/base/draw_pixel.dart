import 'color.dart';
import 'image.dart';

/// Draw a single pixel into the image, applying alpha and opacity blending.
Image drawPixel(Image image, int x, int y, int color, [int opacity = 0xff]) {
  if (image.boundsSafe(x, y)) {
    var pi = y * image.width + x;
    var dst = image[pi];
    image[pi] = alphaBlendColors(dst, color, opacity);
  }
  return image;
}
