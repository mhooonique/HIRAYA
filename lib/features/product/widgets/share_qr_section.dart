// lib/features/product/widgets/share_qr_section.dart

import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';

const _baseUrl = 'https://hiraya.app';

class ShareQrSection extends StatefulWidget {
  final ProductModel product;
  const ShareQrSection({super.key, required this.product});

  @override
  State<ShareQrSection> createState() => _ShareQrSectionState();
}

class _ShareQrSectionState extends State<ShareQrSection> {
  final GlobalKey _qrKey = GlobalKey();

  String get _deepLink => '$_baseUrl/product/${widget.product.id}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share This Innovation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              RepaintBoundary(
                key: _qrKey,
                child: QrImageView(
                  data: _deepLink,
                  version: QrVersions.auto,
                  size: 120,
                  backgroundColor: Colors.white,
                  embeddedImage:
                      const AssetImage('assets/images/logo/final-logo.png'),
                  embeddedImageStyle:
                      const QrEmbeddedImageStyle(size: Size(24, 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan to view',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.offWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _deepLink,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.darkGray,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _copyLink(context),
                            child: const Icon(Icons.copy,
                                size: 16, color: AppColors.navy),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ShareBtn(
                          icon: Icons.link_rounded,
                          label: 'Copy',
                          onTap: () => _copyLink(context),
                        ),
                        const SizedBox(width: 8),
                        ShareBtn(
                          icon: Icons.share_rounded,
                          label: 'Share',
                          onTap: () => _shareLink(),
                          filled: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _downloadQr(context),
            icon: const Icon(Icons.download, size: 16),
            label: const Text(
              'Download QR Code',
              style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.navy),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _deepLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard',
            style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareLink() async {
    await Share.share(
      '🚀 Check out "${widget.product.name}" on HIRAYA — the Philippine Innovation Marketplace!\n\n$_deepLink',
      subject: widget.product.name,
    );
  }

  Future<void> _downloadQr(BuildContext context) async {
    try {
      final boundary = _qrKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'hiraya-qr-${widget.product.id}.png')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download QR code',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ─── SHARE BUTTON ─────────────────────────────────────────────────────────────
class ShareBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const ShareBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: filled ? AppColors.navy : AppColors.lightGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: filled ? Colors.white : AppColors.darkGray),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: filled ? Colors.white : AppColors.darkGray,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}