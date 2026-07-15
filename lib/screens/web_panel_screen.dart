import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/device.dart';

/// Cihazın kendi web kumanda panelini (http://ip:port/) uygulama içinde açar.
/// GX RCU'nun yaptığı yöntem — Sungate/Hiremco/VIP gibi kutularda çalışır.
class WebPanelView extends StatefulWidget {
  final Device device;
  const WebPanelView({super.key, required this.device});

  @override
  State<WebPanelView> createState() => _WebPanelViewState();
}

class _WebPanelViewState extends State<WebPanelView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;

  String get _url {
    final p = widget.device.port;
    final portPart = p == 80 ? '' : ':$p';
    return 'http://${widget.device.host}$portPart/';
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121417))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() {
              _loading = true;
              _error = false;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() {
              _loading = false;
              _error = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));
  }

  void _reload() {
    setState(() {
      _error = false;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_error) WebViewWidget(controller: _controller),
        if (_loading && !_error)
          const Center(child: CircularProgressIndicator()),
        if (_error)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 56, color: Colors.white24),
                const SizedBox(height: 12),
                Text('Web paneli açılamadı\n$_url',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'webReload',
            backgroundColor: const Color(0xFF2E7BE5),
            onPressed: _reload,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}
