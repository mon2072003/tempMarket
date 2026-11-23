import 'package:flutter/material.dart';

class DeliveryMapPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  DeliveryMapPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF131C2E) : const Color(0xFFE8EEF5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw City Block Grids & Parks
    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    // Draw some stylized neighborhood blocks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.12, size.width * 0.35, size.height * 0.22),
        const Radius.circular(12),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.08, size.width * 0.38, size.height * 0.28),
        const Radius.circular(12),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.55, size.width * 0.40, size.height * 0.35),
        const Radius.circular(12),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.60, size.height * 0.52, size.width * 0.32, size.height * 0.36),
        const Radius.circular(12),
      ),
      blockPaint,
    );

    // Green Park
    final parkPaint = Paint()
      ..color = (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7)).withAlpha(150)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.18, size.height * 0.40, size.width * 0.25, size.height * 0.10),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // Roads (Light Gray / Dark Gray Grid)
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadCenterPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPath = Path();
    // Horizontal main roads
    gridPath.moveTo(0, size.height * 0.38);
    gridPath.lineTo(size.width, size.height * 0.38);

    gridPath.moveTo(0, size.height * 0.75);
    gridPath.lineTo(size.width, size.height * 0.75);

    // Vertical main roads
    gridPath.moveTo(size.width * 0.48, 0);
    gridPath.lineTo(size.width * 0.48, size.height);

    canvas.drawPath(gridPath, roadPaint);
    canvas.drawPath(gridPath, roadCenterPaint);

    // Route Polyline (Curved realistic path from store to destination)
    final routeStart = Offset(size.width * 0.18, size.height * 0.25);
    final controlPoint1 = Offset(size.width * 0.48, size.height * 0.25);
    final intermediate1 = Offset(size.width * 0.48, size.height * 0.55);
    final controlPoint2 = Offset(size.width * 0.48, size.height * 0.75);
    final routeEnd = Offset(size.width * 0.82, size.height * 0.75);

    final fullRoute = Path()
      ..moveTo(routeStart.dx, routeStart.dy)
      ..lineTo(controlPoint1.dx, controlPoint1.dy)
      ..lineTo(intermediate1.dx, intermediate1.dy)
      ..lineTo(controlPoint2.dx, controlPoint2.dy)
      ..lineTo(routeEnd.dx, routeEnd.dy);

    // Outer Glow / Route Background
    final routeBgPaint = Paint()
      ..color = primaryColor.withAlpha(40)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullRoute, routeBgPaint);

    // Remaining Route (Dashed / Dimmed)
    final remainingPaint = Paint()
      ..color = primaryColor.withAlpha(90)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullRoute, remainingPaint);

    // Completed Route Segment
    final pathMetrics = fullRoute.computeMetrics();
    Offset currentDriverPos = routeStart;
    double currentAngle = 0.0;

    for (final metric in pathMetrics) {
      final extractLength = metric.length * progress.clamp(0.01, 1.0);
      final completedPath = metric.extractPath(0.0, extractLength);

      final completedPaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(completedPath, completedPaint);

      final tangent = metric.getTangentForOffset(extractLength);
      if (tangent != null) {
        currentDriverPos = tangent.position;
        currentAngle = tangent.angle;
      }
    }

    // 1. Draw Store / Warehouse Pin
    _drawMarker(
      canvas: canvas,
      position: routeStart,
      icon: Icons.storefront,
      color: secondaryColor,
      label: 'نقطة الانطلاق (المتجر)',
    );

    // 2. Draw Customer Destination Pin
    _drawMarker(
      canvas: canvas,
      position: routeEnd,
      icon: Icons.location_on,
      color: const Color(0xFFEF4444),
      label: 'عنوان التوصيل (العميل)',
    );

    // 3. Draw Moving Courier / Driver Marker
    _drawDriverMarker(
      canvas: canvas,
      position: currentDriverPos,
      angle: currentAngle,
    );
  }

  void _drawMarker({
    required Canvas canvas,
    required Offset position,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    // Outer shadow circle
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(position.translate(0, 2), 16, shadowPaint);

    // Pin circle
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 16, circlePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, 16, borderPaint);

    // Icon text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      position.translate(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  void _drawDriverMarker({
    required Canvas canvas,
    required Offset position,
    required double angle,
  }) {
    // Pulse ring
    final pulsePaint = Paint()
      ..color = primaryColor.withAlpha(50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 28, pulsePaint);

    final haloPaint = Paint()
      ..color = primaryColor.withAlpha(120)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 20, haloPaint);

    // Vehicle circle
    final carPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 14, carPaint);

    final carBorder = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(position, 14, carBorder);

    // Delivery Motorcycle / Van icon
    final icon = Icons.delivery_dining;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: primaryColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DeliveryMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}
