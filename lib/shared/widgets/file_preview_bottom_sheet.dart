import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Simple data class for the preview sheet ──────────────
class PreviewFile {
  final String name;       // display name, e.g. "Lecture.pdf"
  final String type;       // "PDF" | "PPT" | "Note" | "Image" …
  final String? localPath; // path on device (if already downloaded)
  final String? remoteUrl; // full Cloudinary URL

  const PreviewFile({
    required this.name,
    required this.type,
    this.localPath,
    this.remoteUrl,
  });

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';

  bool get isPdf {
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

  bool get isDoc {
    if (['doc', 'docx'].contains(extension)) return true;
    return type.toLowerCase() == 'doc';
  }

  bool get isText => extension == 'txt' || type.toLowerCase() == 'note';

  bool get hasContent => localPath != null || remoteUrl != null;
}

// ── Entry point ───────────────────────────────────────────
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
  // ── PDF state ─────────────────────────────────────────
  final PdfViewerController _pdfController = PdfViewerController();
  double _zoom = 1.0;
  int _pdfCurrentPage = 1;
  int _pdfTotalPages = 1;

  /// PDF bytes downloaded from Cloudinary — null until fetch completes.
  Uint8List? _pdfBytes;
  bool _pdfLoading = false;
  String? _pdfError;

  // ── Colours ───────────────────────────────────────────
  static const _bg          = Color(0xFF1C1C1E);
  static const _surface     = Color(0xFF2C2C2E);
  static const _gold        = Color(0xFFB8860B);
  static const _goldLight   = Color(0xFFD4A017);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecond  = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    // If this is a PDF from a remote URL, pre-fetch the bytes immediately
    // so SfPdfViewer.memory() gets raw bytes instead of hitting Cloudinary
    // with a potentially wrong Content-Type header.
    if (widget.file.isPdf &&
        widget.file.localPath == null &&
        widget.file.remoteUrl != null) {
      _fetchPdfBytes(widget.file.remoteUrl!);
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  // ── Download PDF bytes into memory ────────────────────
  Future<void> _fetchPdfBytes(String url) async {
    if (!mounted) return;
    setState(() {
      _pdfLoading = true;
      _pdfError = null;
    });

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw Exception('Download timed out'),
      );

      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      if (!mounted) return;
      setState(() {
        _pdfBytes = response.bodyBytes;
        _pdfLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pdfError = 'Could not download PDF: ${e.toString().replaceFirst('Exception: ', '')}';
        _pdfLoading = false;
      });
    }
  }

  // ── Share ─────────────────────────────────────────────
  void _onShare() {
    if (widget.file.localPath != null) {
      SharePlus.instance.share(
        ShareParams(files: [XFile(widget.file.localPath!)], text: widget.file.name),
      );
    } else if (widget.file.remoteUrl != null) {
      SharePlus.instance.share(
        ShareParams(text: widget.file.remoteUrl!, subject: widget.file.name),
      );
    }
  }

  // ── Root build ────────────────────────────────────────
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

  Widget _handle() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: _textSecond.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Preview: ${widget.file.name}',
            style: const TextStyle(
              color: _textPrimary, fontSize: 14,
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

  // ── Route to viewer ───────────────────────────────────
  Widget _body() {
    if (!widget.file.hasContent) {
      return _centeredMessage(Icons.folder_open, 'No file attached to this material.');
    }
    if (widget.file.isPdf) return _pdfViewer();
    // For non-PDF types, we need a remote URL for the web/image viewers
    final url = widget.file.remoteUrl;
    if (url == null) return _unsupportedViewer();
    if (widget.file.isPpt)   return _webViewer(url, useGoogleDocs: true);
    if (widget.file.isImage) return _imageViewer();
    if (widget.file.isDoc)   return _webViewer(url, useGoogleDocs: true);
    // txt / note / unknown → Google Docs viewer
    return _webViewer(url, useGoogleDocs: true);
  }

  // ── PDF viewer — downloads bytes first to avoid Cloudinary MIME issues ──
  Widget _pdfViewer() {
    final localPath = widget.file.localPath;

    // ── Local file: serve directly
    if (localPath != null) {
      return _pdfStack(
        child: SfPdfViewer.file(
          File(localPath),
          controller: _pdfController,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          initialZoomLevel: _zoom,
          onDocumentLoadFailed: (d) => setState(() => _pdfError = d.description),
          onPageChanged: _onPageChanged,
        ),
      );
    }

    // ── Still downloading
    if (_pdfLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _gold),
            SizedBox(height: 16),
            Text('Loading PDF…', style: TextStyle(color: _textSecond, fontSize: 13)),
          ],
        ),
      );
    }

    // ── Download failed
    if (_pdfError != null) {
      return _errorView(_pdfError!, widget.file.remoteUrl);
    }

    // ── Bytes ready — use SfPdfViewer.memory to bypass MIME/redirect issues
    if (_pdfBytes != null) {
      return _pdfStack(
        child: SfPdfViewer.memory(
          _pdfBytes!,
          controller: _pdfController,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          initialZoomLevel: _zoom,
          onDocumentLoadFailed: (d) => setState(() => _pdfError = d.description),
          onPageChanged: _onPageChanged,
        ),
      );
    }

    // ── Should not reach here, but handle gracefully
    return _unsupportedViewer();
  }

  /// Wraps the PDF viewer widget in a Stack with the control bar.
  Widget _pdfStack({required Widget child}) {
    return Stack(
      children: [
        child,
        if (_pdfError != null)
          _errorView(_pdfError!, widget.file.remoteUrl),
        if (_pdfError == null)
          Positioned(
            bottom: 16, right: 16,
            child: _bottomBar(showPageNav: true, isPdfZoom: true),
          ),
      ],
    );
  }

  void _onPageChanged(PdfPageChangedDetails d) {
    setState(() {
      _pdfCurrentPage = d.newPageNumber;
      _pdfTotalPages  = _pdfController.pageCount;
    });
  }

  // ── Web viewer (Google Docs or direct URL) ────────────
  Widget _webViewer(String url, {bool useGoogleDocs = false}) {
    final viewerUrl = useGoogleDocs
        ? 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}&embedded=true'
        : url;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
              ),
              onReceivedError: (controller, request, error) =>
                  debugPrint('WebView error: ${error.description}'),
            ),
          ),
        ),
        Positioned(
          bottom: 24, right: 24,
          child: _bottomBar(showPageNav: false, isPdfZoom: false),
        ),
      ],
    );
  }

  // ── Image viewer ──────────────────────────────────────
  Widget _imageViewer() {
    final path = widget.file.localPath;
    final url  = widget.file.remoteUrl;
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: path != null
            ? Image.file(
                File(path),
                errorBuilder: (_, e, st) => _errorView('Failed to load image.', url),
              )
            : url != null
            ? Image.network(
                url,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: _gold)),
                errorBuilder: (_, e, st) => _errorView('Failed to load image.', url),
              )
            : const SizedBox(),
      ),
    );
  }

  // ── Error view with optional "Open in Browser" button ─
  Widget _errorView(String message, String? fallbackUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (fallbackUrl != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _launchInBrowser(fallbackUrl),
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text('Open in Browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Unsupported / no URL ──────────────────────────────
  Widget _unsupportedViewer() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 64,
              color: _gold.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(widget.file.name,
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Preview not available.',
            style: TextStyle(color: _textSecond, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (widget.file.remoteUrl != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _launchInBrowser(widget.file.remoteUrl!),
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Open in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _centeredMessage(IconData icon, String text) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: _gold.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        Text(text,
            style: const TextStyle(color: _textSecond, fontSize: 14),
            textAlign: TextAlign.center),
      ],
    ),
  );

  Future<void> _launchInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Bottom control bar ────────────────────────────────
  Widget _bottomBar({required bool showPageNav, required bool isPdfZoom}) {
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
          GestureDetector(
            onTap: () {
              final z = (_zoom - 0.25).clamp(0.5, 3.0);
              setState(() => _zoom = z);
              if (isPdfZoom) _pdfController.zoomLevel = z;
            },
            child: const Icon(Icons.remove, color: _textPrimary, size: 16),
          ),
          SizedBox(
            width: 70,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbColor: _goldLight,
                activeTrackColor: _gold,
                inactiveTrackColor: _textSecond.withValues(alpha: 0.3),
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
                  if (isPdfZoom) _pdfController.zoomLevel = v;
                },
              ),
            ),
          ),
          Text(
            '${(_zoom * 100).round()}%',
            style: const TextStyle(color: _textPrimary, fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          if (showPageNav) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _pdfCurrentPage > 1 ? () => _pdfController.previousPage() : null,
              child: Icon(Icons.chevron_left,
                  color: _pdfCurrentPage > 1 ? _textPrimary : _textSecond, size: 20),
            ),
            Text('$_pdfCurrentPage / $_pdfTotalPages',
                style: const TextStyle(color: _textSecond, fontSize: 11)),
            GestureDetector(
              onTap: _pdfCurrentPage < _pdfTotalPages ? () => _pdfController.nextPage() : null,
              child: Icon(Icons.chevron_right,
                  color: _pdfCurrentPage < _pdfTotalPages ? _textPrimary : _textSecond, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
