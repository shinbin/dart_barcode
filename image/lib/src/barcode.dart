/*
 * Copyright (C) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:image/image.dart';

/// Store the width and height of a rendered text
class BitmapFontMetrics {
  /// Create a BitmapFontMetrics structure
  const BitmapFontMetrics(this.width, this.height);

  /// The width of the text in pixels
  final int width;

  /// The height of the text in pixels
  final int height;
}

/// Extension on BitmapFont to add metrics calculation
extension BitmapFontMetricsFunctions on BitmapFont {
  /// Calculate the width and height in pixels of a text string
  BitmapFontMetrics getMetrics(String string) {
    if (string.isEmpty) {
      return const BitmapFontMetrics(0, 0);
    }

    var width = 0;
    var height = 0;
    final cu = string.codeUnits;

    for (var c in cu.sublist(0, cu.length - 1)) {
      if (!characters.containsKey(c)) {
        continue;
      }

      final ch = characters[c]!;
      width += ch.xAdvance;
      if (height < ch.height + ch.yOffset) {
        height = ch.height + ch.yOffset;
      }
    }

    final c = cu.last;
    if (characters.containsKey(c)) {
      final ch = characters[c]!;
      width += ch.width;
      if (height < ch.height + ch.yOffset) {
        height = ch.height + ch.yOffset;
      }
    }

    return BitmapFontMetrics(width, height);
  }
}

/// Create a Barcode
void drawBarcode(
  Image image,
  Barcode barcode,
  String data, {
  int x = 0,
  int y = 0,
  int? width,
  int? height,
  BitmapFont? font,
  int? textPadding,
  int color = 0xff000000,
}) {
  width ??= image.width;
  height ??= image.height;
  textPadding ??= 0;

  final recipe = barcode.make(
    data,
    width: width.toDouble(),
    height: height.toDouble(),
    drawText: font != null,
    fontHeight: font?.lineHeight.toDouble(),
    textPadding: textPadding.toDouble(),
  );

  _drawBarcode(image, recipe, x, y, font, color);
}

/// Create a Barcode
void drawBarcodeBytes(
  Image image,
  Barcode barcode,
  Uint8List bytes, {
  int x = 0,
  int y = 0,
  int? width,
  int? height,
  BitmapFont? font,
  int? textPadding,
  int color = 0xff000000,
}) {
  width ??= image.width;
  height ??= image.height;
  textPadding ??= 0;

  final recipe = barcode.makeBytes(
    bytes,
    width: width.toDouble(),
    height: height.toDouble(),
    drawText: font != null,
    fontHeight: font?.lineHeight.toDouble(),
    textPadding: textPadding.toDouble(),
  );

  _drawBarcode(image, recipe, x, y, font, color);
}

void _drawBarcode(
  Image image,
  Iterable<BarcodeElement> recipe,
  int x,
  int y,
  BitmapFont? font,
  int color,
) {
  final imageColor = ColorRgba8((color >> 16) & 0xff, (color >> 8) & 0xff,
      color & 0xff, (color >> 24) & 0xff);

  // Draw the barcode
  for (var elem in recipe) {
    if (elem is BarcodeBar) {
      if (elem.black) {
        // Draw one black bar
        fillRect(
          image,
          x1: (x + elem.left).round(),
          y1: (y + elem.top).round(),
          x2: (x + elem.right).round(),
          y2: (y + elem.bottom).round(),
          color: imageColor,
        );
      }
    } else if (elem is BarcodeText) {
      // Get string dimensions
      final metrics = font!.getMetrics(elem.text);
      final top = y + elem.top + elem.height - font.size;
      late double left;

      // Center the text
      switch (elem.align) {
        case BarcodeTextAlign.left:
          left = x + elem.left;
          break;
        case BarcodeTextAlign.center:
          left = x + elem.left + (elem.width - metrics.width) / 2;
          break;
        case BarcodeTextAlign.right:
          left = x + elem.left + elem.width - metrics.width;
          break;
      }

      // Draw some text using 14pt arial font
      drawString(
        image,
        elem.text,
        font: font,
        x: left.round(),
        y: top.round(),
        color: imageColor,
      );
    }
  }
}
