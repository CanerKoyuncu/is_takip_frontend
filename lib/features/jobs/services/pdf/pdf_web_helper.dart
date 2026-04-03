// Web-specific PDF helper
// This file is only used on web platform

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Opens PDF in a new browser window for preview (web only)
/// User can share or download from the browser's PDF viewer
void openPdfInNewWindow(Uint8List pdfBytes, String filename) {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Open PDF in new tab for preview (no download attribute)
  // User can share or download from browser's PDF viewer
  final anchor = html.AnchorElement(href: url)
    ..target = '_blank'
    // Removed download attribute to open in preview mode
    ..click();

  // Clean up the URL after a delay
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
    anchor.remove();
  });
}
