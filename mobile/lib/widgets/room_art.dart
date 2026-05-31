import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class RoomScene extends StatelessWidget {
  const RoomScene({
    super.key,
    required this.layoutKey,
    this.paletteKey = 'cool',
    this.height = 170,
  });

  final String layoutKey;
  final String paletteKey;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: RoomScenePainter(
          items: roomLayouts[layoutKey] ?? roomLayouts['bedB']!,
          palette: roomPalettes[paletteKey] ?? roomPalettes['cool']!,
        ),
      ),
    );
  }
}

class RoomScenePainter extends CustomPainter {
  RoomScenePainter({required this.items, required this.palette});

  final List<RoomItem> items;
  final RoomPalette palette;

  static const double isoU = 19;
  static const double isoV = .56;
  static const double isoH = 15;

  Offset iso(double gx, double gy, double gz, Size size) {
    final cx = size.width / 2;
    final cy = math.max(44.0, size.height * .28);
    return Offset(
      cx + (gx - gy) * isoU,
      cy + (gx + gy) * isoU * isoV - gz * isoH,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [palette.sky, _shade(palette.sky, -8)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    const rw = 9.0;
    const rd = 7.0;
    const wh = 4.4;
    final l0 = iso(0, 0, 0, size);
    final l1 = iso(0, rd, 0, size);
    final lt0 = iso(0, 0, wh, size);
    final lt1 = iso(0, rd, wh, size);
    final r1 = iso(rw, 0, 0, size);
    final rt1 = iso(rw, 0, wh, size);
    final f11 = iso(rw, rd, 0, size);

    _poly(canvas, [l0, l1, lt1, lt0], palette.wallLeft);
    _poly(canvas, [l0, r1, rt1, lt0], palette.wallRight);
    _poly(canvas, [l0, r1, f11, l1], palette.floor, stroke: palette.floorEdge);

    _poly(canvas, [
      iso(2.2, 0, 1.4, size),
      iso(4.6, 0, 1.4, size),
      iso(4.6, 0, 3.4, size),
      iso(2.2, 0, 3.4, size),
    ], const Color(0xFFCDE3EA).withValues(alpha: .9));

    final sorted = [...items]..sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    for (final item in sorted) {
      if (item.type == 'rug') {
        _rug(canvas, size, item, furnitureColors['rug']!);
      } else {
        _box(
          canvas,
          size,
          item,
          furnitureColors[item.type] ?? const Color(0xFF9AA8AA),
        );
      }
    }
  }

  void _rug(Canvas canvas, Size size, RoomItem item, Color color) {
    final a = iso(item.x, item.y, .02, size);
    final b = iso(item.x + item.w, item.y, .02, size);
    final c = iso(item.x + item.w, item.y + item.d, .02, size);
    final d = iso(item.x, item.y + item.d, .02, size);
    _poly(canvas, [a, b, c, d], color.withValues(alpha: .9));
  }

  void _box(Canvas canvas, Size size, RoomItem item, Color color) {
    final p10 = iso(item.x + item.w, item.y, 0, size);
    final p11 = iso(item.x + item.w, item.y + item.d, 0, size);
    final p01 = iso(item.x, item.y + item.d, 0, size);
    final t00 = iso(item.x, item.y, item.h, size);
    final t10 = iso(item.x + item.w, item.y, item.h, size);
    final t11 = iso(item.x + item.w, item.y + item.d, item.h, size);
    final t01 = iso(item.x, item.y + item.d, item.h, size);
    _poly(canvas, [p01, p11, t11, t01], _shade(color, -6));
    _poly(canvas, [p10, p11, t11, t10], _shade(color, -28));
    _poly(canvas, [t00, t10, t11, t01], _shade(color, 22));
  }

  void _poly(Canvas canvas, List<Offset> points, Color color, {Color? stroke}) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, Paint()..color = color);
    if (stroke != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  Color _shade(Color color, int amount) {
    int clamp(num v) => v.clamp(0, 255).round();
    return Color.fromARGB(
      clamp(color.a * 255),
      clamp(color.r * 255 + amount),
      clamp(color.g * 255 + amount),
      clamp(color.b * 255 + amount),
    );
  }

  @override
  bool shouldRepaint(covariant RoomScenePainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.palette != palette;
  }
}

class FloorPlanView extends StatelessWidget {
  const FloorPlanView({
    super.key,
    required this.layout,
    this.height = 196,
    this.showLabels = true,
  });

  final FloorLayout layout;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: FloorPlanPainter(
          items: floorPlans[layout] ?? floorPlans[FloorLayout.before]!,
          showLabels: showLabels,
        ),
      ),
    );
  }
}

class FloorPlanPainter extends CustomPainter {
  FloorPlanPainter({required this.items, required this.showLabels});

  final List<PlanItem> items;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 16.0;
    final rect = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );
    final wall = Paint()
      ..color = AppColors.border2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFBFDFD),
    );

    final grid = Paint()
      ..color = AppColors.ink.withValues(alpha: .045)
      ..strokeWidth = 1;
    for (var i = 0; i <= 12; i++) {
      final x = rect.left + rect.width / 12 * i;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
    }
    for (var i = 0; i <= 9; i++) {
      final y = rect.top + rect.height / 9 * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      wall,
    );

    final window = Rect.fromLTWH(
      rect.left + rect.width * .4,
      rect.top - 2,
      rect.width * .2,
      4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, const Radius.circular(2)),
      Paint()..color = AppColors.teal,
    );
    _label(
      canvas,
      'window',
      Offset(window.left, rect.top - 13),
      AppColors.ink2,
      9,
    );

    final doorY = rect.top + rect.height * .55;
    canvas.drawArc(
      Rect.fromLTWH(rect.left, doorY, rect.height * .18, rect.height * .18),
      0,
      math.pi / 2,
      false,
      Paint()
        ..color = AppColors.border2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _label(
      canvas,
      'door',
      Offset(rect.left + 6, doorY - 16),
      AppColors.ink2,
      9,
    );

    for (final item in items) {
      final x = rect.left + item.x / 12 * rect.width;
      final y = rect.top + item.y / 9 * rect.height;
      final w = item.w / 12 * rect.width;
      final h = item.h / 9 * rect.height;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(4),
      );
      final stroke = item.fixed
          ? AppColors.warm
          : (item.moved ? AppColors.teal : const Color(0xFFB6C6CB));
      final fill = item.fixed
          ? AppColors.warnTint
          : (item.moved ? const Color(0xFFDBF1EC) : AppColors.surface2);
      canvas.drawRRect(r, Paint()..color = fill);
      canvas.drawRRect(
        r,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = item.fixed || item.moved ? 2 : 1.3,
      );
      if (showLabels) {
        _label(
          canvas,
          item.label,
          Offset(x + w / 2, y + h / 2),
          AppColors.ink2,
          math.min(11, w / (item.label.length * .55)),
        );
      }
    }
  }

  void _label(Canvas canvas, String text, Offset at, Color color, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppText.xs(
          color: color,
          weight: FontWeight.w700,
        ).copyWith(fontSize: size),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: 90);
    painter.paint(
      canvas,
      Offset(at.dx - painter.width / 2, at.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.showLabels != showLabels;
  }
}
