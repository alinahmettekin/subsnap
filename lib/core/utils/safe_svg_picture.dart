import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG yükleme hatalarını yakalayan güvenli bir widget
/// Parse hatalarında fallback gösterir
class SafeSvgPicture extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? fallback;

  const SafeSvgPicture.network({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return SvgPicture.network(
            url,
            width: width,
            height: height,
            fit: fit,
            placeholderBuilder: placeholder != null
                ? (context) => placeholder!
                : null,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ [SafeSvgPicture] SVG yükleme hatası: $error');
              debugPrint('Stack trace: $stackTrace');
              return const SizedBox.shrink();
            },
          );
        } catch (e, stackTrace) {
          debugPrint('❌ [SafeSvgPicture] SVG parse hatası: $e');
          debugPrint('Stack trace: $stackTrace');
          // Fallback göster
          if (fallback != null) {
            return fallback!;
          }
          // Varsayılan fallback: boş container
          return SizedBox(
            width: width,
            height: height,
            child: const Icon(Icons.error_outline, color: Colors.grey),
          );
        }
      },
    );
  }
}
