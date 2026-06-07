import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// ─────────────────────────────────────────────────────────
//  pubspec.yaml — add these packages:
//
//  dependencies:
//    syncfusion_flutter_pdfviewer: ^25.1.35
//    flutter_inappwebview: ^6.0.0
//    share_plus: ^9.0.0
//    file_picker: ^8.0.0       (already added for screen)
// ─────────────────────────────────────────────────────────

// ── Simple data class for the preview sheet ───────────────
// Separate from your full ReferenceMaterial model to keep
// the widget independent and reusable.
class PreviewFile {
  final String name; // display name, e.g. "Lecture.pdf"
  final String type; // "PDF" | "PPT" | "Note" | "Image"
  final String? localPath; // path on device (if downloaded)
  final String? remoteUrl; // full URL from backend

  const PreviewFile({
    required this.name,
    required this.type,
    this.localPath,
    this.remoteUrl,
  });

  String get extension => name.split('.').last.toLowerCase();

  bool get isPdf {
    // Check filename extension first, then fall back to type string
    if (extension == 'pdf') return true;
    return type.toLowerCase() == 'pdf';
  }

  bool get isPpt {
    if (extension == 'ppt' || extension == 'pptx') return true;
    return type.toLowerCase() == 'ppt';
  }

  bool get isImage {
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) return true;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(type.toLowerCase());
  }

  /// True when there is content to show (URL or local file exists).
  bool get hasContent => localPath != null || remoteUrl != null;
}

// ─────────────────────────────────────────────────────────
//  Entry point — call this from your reference card onTap
// ─────────────────────────────────────────────────────────
void showFilePreview(BuildContext context, {required PreviewFile file}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FilePreviewSheet(file: file),
  );
}

// ─────────────────────────────────────────────────────────
class FilePreviewSheet extends StatefulWidget {
  final PreviewFile file;
  const FilePreviewSheet({super.key, required this.file});

  @override
  State<FilePreviewSheet> createState() => _FilePreviewSheetState();
}

class _FilePreviewSheetState extends State<FilePreviewSheet> {
  double _zoom = 1.0;
  int _pdfCurrentPage = 1;
  int _pdfTotalPages = 1;
  final PdfViewerController _pdfController = PdfViewerController();

  // ── VibeFlow colours ──────────────────────────────────
  static const _bg = Color(0xFF1C1C1E);
  static const _surface = Color(0xFF2C2C2E);
  static const _gold = Color(0xFFB8860B);
  static const _goldLight = Color(0xFFD4A017);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFF8E8E93);

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  void _onShare() {
    if (widget.file.localPath != null) {
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.file.localPath!)],
          text: widget.file.name,
        ),
      );
    } else if (widget.file.remoteUrl != null) {
      SharePlus.instance.share(
        ShareParams(text: widget.file.remoteUrl!, subject: widget.file.name),
      );
    }
  }

  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _handle(),
          _header(),
          const Divider(color: Color(0xFF3A3A3C), height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  // ── Drag handle ──────────────────────────────────────
  Widget _handle() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: _textSecondary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  // ── Header row ────────────────────────────────────────
  Widget _header() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: _textPrimary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Preview: ${widget.file.name}',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          onPressed: _onShare,
          icon: const Icon(Icons.share_outlined, color: _textPrimary, size: 22),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ],
    ),
  );

  // ── Route to the right viewer ─────────────────────────
  Widget _body() {
    // No content at all — show a clear message instead of blank screen
    if (!widget.file.hasContent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 64, color: _gold.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'No file attached to this material.',
              style: TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (widget.file.isPdf) return _pdfViewer();
    if (widget.file.isPpt) return _pptViewer();
    if (widget.file.isImage) return _imageViewer();
    // Has a URL/file but unknown type — open via in-app browser
    return _genericWebViewer();
  }

  // ── PDF viewer ────────────────────────────────────────
  Widget _pdfViewer() {
    final path = widget.file.localPath;
    final url = widget.file.remoteUrl;

    Widget viewer;
    if (path != null) {
      viewer = SfPdfViewer.file(
        File(path),
        controller: _pdfController,
        pageLayoutMode: PdfPageLayoutMode.single,
        initialZoomLevel: _zoom,
        onPageChanged: (d) => setState(() {
          _pdfCurrentPage = d.newPageNumber;
          _pdfTotalPages = _pdfController.pageCount;
        }),
      );
    } else if (url != null) {
      viewer = SfPdfViewer.network(
        url,
        controller: _pdfController,
        pageLayoutMode: PdfPageLayoutMode.single,
        initialZoomLevel: _zoom,
        onPageChanged: (d) => setState(() {
          _pdfCurrentPage = d.newPageNumber;
          _pdfTotalPages = _pdfController.pageCount;
        }),
      );
    } else {
      return _unsupportedViewer();
    }

    return Stack(
      children: [
        viewer,
        Positioned(bottom: 16, right: 16, child: _bottomBar(showPageNav: true)),
      ],
    );
  }

  // ── PPT viewer via Google Docs ────────────────────────
  Widget _pptViewer() {
    final url = widget.file.remoteUrl;
    if (url == null) return _unsupportedViewer();

    final googleUrl =
        'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(googleUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: _bottomBar(showPageNav: false),
        ),
      ],
    );
  }

  // ── Image viewer ──────────────────────────────────────
  Widget _imageViewer() {
    final path = widget.file.localPath;
    final url = widget.file.remoteUrl;
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: path != null
            ? Image.file(File(path))
            : url != null
            ? Image.network(url)
            : const SizedBox(),
      ),
    );
  }

  // ── Unsupported type ──────────────────────────────────
  Widget _unsupportedViewer() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 64,
            color: _gold.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.file.name,
            style: const TextStyle(color: _textPrimary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Preview not available.\nDownload to open externally.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Generic web viewer — for doc/txt/other files with a URL ──
  Widget _genericWebViewer() {
    final url = widget.file.remoteUrl;
    if (url == null) return _unsupportedViewer();

    // Use Google Docs viewer as a universal fallback
    final viewerUrl =
        'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            transparentBackground: true,
          ),
        ),
      ),
    );
  }

  // ── Bottom control bar (zoom + page nav) ──────────────
  Widget _bottomBar({required bool showPageNav}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _surface.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Zoom minus
          GestureDetector(
            onTap: () {
              final newZoom = (_zoom - 0.25).clamp(0.5, 3.0);
              setState(() => _zoom = newZoom);
              _pdfController.zoomLevel = newZoom;
            },
            child: const Icon(Icons.remove, color: _textPrimary, size: 16),
          ),

          // ── Zoom slider
          SizedBox(
            width: 70,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbColor: _goldLight,
                activeTrackColor: _gold,
                inactiveTrackColor: _textSecondary.withValues(alpha: 0.3),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: _zoom,
                min: 0.5,
                max: 3.0,
                onChanged: (v) {
                  setState(() => _zoom = v);
                  _pdfController.zoomLevel = v;
                },
              ),
            ),
          ),

          // ── Zoom label
          Text(
            '${(_zoom * 100).round()}%',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          // ── Page nav (PDF only)
          if (showPageNav) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _pdfCurrentPage > 1
                  ? () => _pdfController.previousPage()
                  : null,
              child: Icon(
                Icons.chevron_left,
                color: _pdfCurrentPage > 1 ? _textPrimary : _textSecondary,
                size: 20,
              ),
            ),
            Text(
              '$_pdfCurrentPage / $_pdfTotalPages',
              style: const TextStyle(color: _textSecondary, fontSize: 11),
            ),
            GestureDetector(
              onTap: _pdfCurrentPage < _pdfTotalPages
                  ? () => _pdfController.nextPage()
                  : null,
              child: Icon(
                Icons.chevron_right,
                color: _pdfCurrentPage < _pdfTotalPages
                    ? _textPrimary
                    : _textSecondary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
