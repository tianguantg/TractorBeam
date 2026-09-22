import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';

class SavedWindowPlacement {
  const SavedWindowPlacement({required this.bounds, required this.maximized});

  final Rect bounds;
  final bool maximized;
}

class WindowPlacementStore {
  static File? get _file {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData == null || localAppData.trim().isEmpty) return null;
    return File('$localAppData\\TractorBeamFlutter\\window_placement.json');
  }

  static Future<SavedWindowPlacement?> load() async {
    final file = _file;
    if (file == null || !await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic>) return null;
      final x = (data['x'] as num?)?.toDouble();
      final y = (data['y'] as num?)?.toDouble();
      final width = (data['width'] as num?)?.toDouble();
      final height = (data['height'] as num?)?.toDouble();
      if (x == null ||
          y == null ||
          width == null ||
          height == null ||
          !x.isFinite ||
          !y.isFinite ||
          !width.isFinite ||
          !height.isFinite ||
          width < 640 ||
          height < 420) {
        return null;
      }
      final placement = SavedWindowPlacement(
        bounds: Rect.fromLTWH(x, y, width, height),
        maximized: data['maximized'] == true,
      );
      return SavedWindowPlacement(
        bounds: await _clampToVisibleWorkArea(placement.bounds),
        maximized: placement.maximized,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(SavedWindowPlacement placement) async {
    final file = _file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'x': placement.bounds.left,
          'y': placement.bounds.top,
          'width': placement.bounds.width,
          'height': placement.bounds.height,
          'maximized': placement.maximized,
        }),
        flush: true,
      );
    } catch (_) {
      // Window placement is optional UI state and must never block shutdown.
    }
  }

  static Future<Rect> _clampToVisibleWorkArea(Rect bounds) async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      if (displays.isEmpty) return bounds;
      final workAreas = displays
          .map(
            (display) =>
                (display.visiblePosition ?? Offset.zero) &
                (display.visibleSize ?? display.size),
          )
          .toList();
      final intersects = workAreas.any(
        (area) =>
            area.intersect(bounds).width >= 80 &&
            area.intersect(bounds).height >= 40,
      );
      if (intersects) return bounds;
      final primary = await screenRetriever.getPrimaryDisplay();
      final work =
          (primary.visiblePosition ?? Offset.zero) &
          (primary.visibleSize ?? primary.size);
      final width = bounds.width.clamp(640.0, work.width);
      final height = bounds.height.clamp(420.0, work.height);
      return Rect.fromLTWH(
        work.left + (work.width - width) / 2,
        work.top + (work.height - height) / 2,
        width,
        height,
      );
    } catch (_) {
      return bounds;
    }
  }
}
