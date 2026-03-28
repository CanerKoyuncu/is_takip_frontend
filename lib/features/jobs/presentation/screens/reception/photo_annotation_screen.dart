import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../widgets/image_annotation_canvas.dart';

/// Fotoğraf üzerinde işaretleme yapma ekranı.
class PhotoAnnotationScreen extends StatefulWidget {
  final String imagePath;
  final String? initialNote;

  const PhotoAnnotationScreen({
    super.key,
    required this.imagePath,
    this.initialNote,
  });

  @override
  State<PhotoAnnotationScreen> createState() => _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends State<PhotoAnnotationScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  Color _strokeColor = Colors.red;
  double _strokeWidth = 5.0;
  final List<Color> _colors = [
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.green,
    Colors.black,
  ];

  bool _isSaving = false;

  Future<void> _saveAnnotation() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final uint8list = byteData.buffer.asUint8List();

      if (kIsWeb) {
        // Web'de Base64 Data URL olarak döndür
        final base64String = base64Encode(uint8list);
        final dataUrl = 'data:image/png;base64,$base64String';
        if (mounted) {
          Navigator.pop(context, dataUrl);
        }
      } else {
        // Native platformlarda dosyaya yaz
        final tempDir = await getTemporaryDirectory();
        final fileName =
            'annotated_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = await io.File(
          '${tempDir.path}/$fileName',
        ).writeAsBytes(uint8list);
        if (mounted) {
          Navigator.pop(context, file.path);
        }
      }
    } catch (e) {
      debugPrint('Error saving annotation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşaretleme kaydedilirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fotoğrafı İşaretle'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveAnnotation,
              child: const Text(
                'TAMAM',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Drawing Area
          Expanded(
            child: RepaintBoundary(
              key: _repaintKey,
              child: ImageAnnotationCanvas(
                image:
                    kIsWeb ||
                        widget.imagePath.startsWith('http') ||
                        widget.imagePath.startsWith('blob:') ||
                        widget.imagePath.startsWith('data:')
                    ? NetworkImage(widget.imagePath) as ImageProvider
                    : FileImage(io.File(widget.imagePath)),
                strokeColor: _strokeColor,
                strokeWidth: _strokeWidth,
              ),
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color & Size controls
                  Row(
                    children: [
                      // Colors
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _colors.map((color) {
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _strokeColor = color),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _strokeColor == color
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      if (_strokeColor == color)
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 4,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const VerticalDivider(width: 16),

                      // Sizes
                      DropdownButton<double>(
                        value: _strokeWidth,
                        underline: const SizedBox(),
                        items: [3.0, 5.0, 8.0, 12.0].map((w) {
                          return DropdownMenuItem<double>(
                            value: w,
                            child: CircleAvatar(
                              radius: w / 2 + 2,
                              backgroundColor: scheme.onSurface,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _strokeWidth = val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          // Note: Accessing _points directly isn't possible, we'd need a controller
                          // For simplicity, we can reload the screen OR pass a GlobalKey to canvas
                          // I'll skip UNDO/CLEAR for this MVP unless I add a Controller class
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Temizleme için geri dönüp tekrar açınız',
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Temizle',
                      ),

                      Text(
                        'Damaged areas marker',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      const SizedBox(width: 48), // Spacer
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
