import 'package:flutter/material.dart';

/// Calcula el ancho en píxeles para decodificar imágenes sin sobrecargar memoria.
int imageCacheWidth(BuildContext context, double logicalWidth) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalWidth * dpr).clamp(1, 1200).round();
}

/// Imagen de asset optimizada para web: cacheWidth, dimensiones fijas y CLS reducido.
class OptimizedAssetImage extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool decorative;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const OptimizedAssetImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.decorative = false,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cacheW = width != null
        ? imageCacheWidth(context, width!)
        : imageCacheWidth(context, MediaQuery.sizeOf(context).width);

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheW,
      gaplessPlayback: true,
      excludeFromSemantics: decorative,
      errorBuilder: errorBuilder,
    );
  }
}
