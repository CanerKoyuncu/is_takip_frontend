import 'package:flutter/material.dart';

/// Her bir çizim satırını (strok) temsil eden model.
class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawingPath({
    required this.points,
    required this.color,
    required this.width,
  });
}

/// Fotoğraf üzerinde işaretleme yapmak için kullanılan çizim alanı.
class ImageAnnotationCanvas extends StatefulWidget {
  final ImageProvider image;
  final ScrollController? scrollController;
  final Color strokeColor;
  final double strokeWidth;
  final Function(List<DrawingPath> paths)? onUpdate;

  const ImageAnnotationCanvas({
    super.key,
    required this.image,
    this.scrollController,
    this.strokeColor = Colors.red,
    this.strokeWidth = 4.0,
    this.onUpdate,
  });

  @override
  State<ImageAnnotationCanvas> createState() => _ImageAnnotationCanvasState();
}

class _ImageAnnotationCanvasState extends State<ImageAnnotationCanvas> {
  final List<DrawingPath> _paths = [];
  List<Offset> _currentPoints = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoints.add(details.localPosition);
    });
    // Canlı güncelleme için geçici olarak yolları güncelle (opsiyonel)
    // widget.onUpdate?.call([..._paths, DrawingPath(...)]);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isNotEmpty) {
      setState(() {
        _paths.add(DrawingPath(
          points: List.of(_currentPoints),
          color: widget.strokeColor,
          width: widget.strokeWidth,
        ));
        _currentPoints = [];
      });
      widget.onUpdate?.call(List.of(_paths));
    }
  }

  void clear() {
    setState(() {
      _paths.clear();
      _currentPoints = [];
    });
    widget.onUpdate?.call([]);
  }

  void undo() {
    if (_paths.isNotEmpty) {
      setState(() {
        _paths.removeLast();
      });
      widget.onUpdate?.call(List.of(_paths));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: widget.image, fit: BoxFit.contain),
          CustomPaint(
            painter: AnnotationPainter(
              paths: _paths,
              currentPoints: _currentPoints,
              currentStrokeColor: widget.strokeColor,
              currentStrokeWidth: widget.strokeWidth,
            ),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final List<Offset> currentPoints;
  final Color currentStrokeColor;
  final double currentStrokeWidth;

  AnnotationPainter({
    required this.paths,
    required this.currentPoints,
    required this.currentStrokeColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 1. Kaydedilmiş tüm yolları çiz
    for (final pathData in paths) {
      if (pathData.points.isEmpty) continue;
      
      paint.color = pathData.color;
      paint.strokeWidth = pathData.width;
      
      final path = Path();
      path.moveTo(pathData.points.first.dx, pathData.points.first.dy);
      
      for (int i = 1; i < pathData.points.length; i++) {
        path.lineTo(pathData.points[i].dx, pathData.points[i].dy);
      }
      
      // Tek nokta ise görünür kılmak için nokta çiz
      if (pathData.points.length == 1) {
        canvas.drawCircle(pathData.points.first, pathData.width / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(path, paint);
      }
    }

    // 2. Şu an çizilmekte olan yolu çiz
    if (currentPoints.isNotEmpty) {
      paint.color = currentStrokeColor;
      paint.strokeWidth = currentStrokeWidth;
      
      final path = Path();
      path.moveTo(currentPoints.first.dx, currentPoints.first.dy);
      
      for (int i = 1; i < currentPoints.length; i++) {
        path.lineTo(currentPoints[i].dx, currentPoints[i].dy);
      }
      
      if (currentPoints.length == 1) {
        canvas.drawCircle(currentPoints.first, currentStrokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return true;
  }
}
