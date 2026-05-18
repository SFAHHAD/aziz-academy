import 'package:flutter/material.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Network image with loading state and an explicit retry control on failure.
class NetworkImageRetry extends StatefulWidget {
  const NetworkImageRetry({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  State<NetworkImageRetry> createState() => _NetworkImageRetryState();
}

class _NetworkImageRetryState extends State<NetworkImageRetry> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    final uri = widget.url;
    return Image.network(
      uri,
      key: ValueKey('$uri-$_attempt'),
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: widget.width ?? 300,
          height: widget.height ?? 200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return SizedBox(
          width: widget.width ?? 300,
          height: widget.height ?? 200,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  context.l10n.networkImageError,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _attempt++),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(context.l10n.networkRetry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
