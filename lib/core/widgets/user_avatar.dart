// lib/core/widgets/user_avatar.dart
//
// A shared avatar widget used everywhere a user's picture / initials appears.
//
// • If [avatarBase64] is non-null and non-empty → shows the image
// • Otherwise → shows a coloured circle with the first initial of [name]
//
// [uploadable] wraps the avatar in a Stack with a camera-icon overlay so the
// user can tap to change their picture. The [onUpload] callback receives the
// raw base64 string (data-URL prefix already stripped).

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';


class UserAvatar extends StatelessWidget {
  final String? avatarBase64;
  final String  name;
  final double  radius;
  final Color?  backgroundColor;
  final Color?  foregroundColor;
  final bool    uploadable;
  final Future<void> Function(String base64)? onUpload;

  const UserAvatar({
    super.key,
    required this.name,
    this.avatarBase64,
    this.radius           = 20,
    this.backgroundColor,
    this.foregroundColor,
    this.uploadable       = false,
    this.onUpload,
  });

  // Deterministic colour from first letter
  static const _palette = [
    AppColors.teal,
    AppColors.sky,
    AppColors.navy,
    AppColors.golden,
    AppColors.crimson,
  ];

  Color get _bg {
    if (backgroundColor != null) return backgroundColor!;
    final letter = name.isNotEmpty ? name.codeUnitAt(0) : 65;
    return _palette[letter % _palette.length].withValues(alpha: 0.18);
  }

  Color get _fg {
    if (foregroundColor != null) return foregroundColor!;
    final letter = name.isNotEmpty ? name.codeUnitAt(0) : 65;
    return _palette[letter % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatar();
    if (!uploadable) return avatar;
    return _UploadableAvatar(
      avatar:   avatar,
      radius:   radius,
      onUpload: onUpload,
    );
  }

  Widget _avatar() {
    final hasImage = avatarBase64 != null && avatarBase64!.isNotEmpty;
    if (hasImage) {
      try {
        return CircleAvatar(
          radius:           radius,
          backgroundImage:  MemoryImage(base64Decode(avatarBase64!)),
          backgroundColor:  _bg,
        );
      } catch (_) {
        // Fall through to initials on decode error
      }
    }
    return CircleAvatar(
      radius:          radius,
      backgroundColor: _bg,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontFamily:  'Poppins',
          fontSize:    radius * 0.9,
          fontWeight:  FontWeight.w700,
          color:       _fg,
        ),
      ),
    );
  }
}

// ── Uploadable wrapper ─────────────────────────────────────────────────────────

class _UploadableAvatar extends StatefulWidget {
  final Widget avatar;
  final double radius;
  final Future<void> Function(String base64)? onUpload;

  const _UploadableAvatar({
    required this.avatar,
    required this.radius,
    this.onUpload,
  });

  @override
  State<_UploadableAvatar> createState() => _UploadableAvatarState();
}

class _UploadableAvatarState extends State<_UploadableAvatar> {
  bool _busy = false;

  void _pick() {
    if (_busy) return;
    final input = html.FileUploadInputElement()
      ..accept = 'image/jpeg,image/png,image/webp'
      ..click();

    input.onChange.listen((event) async {
      final file = input.files?.first;
      if (file == null) return;

      // 300 KB limit on the client side
      if (file.size > 300 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image must be under 300 KB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _busy = true);
      final reader = html.FileReader()..readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes  = reader.result as List<int>;
      final base64 = base64Encode(bytes);

      if (widget.onUpload != null) await widget.onUpload!(base64);
      if (mounted) setState(() => _busy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: Stack(
        children: [
          widget.avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width:       widget.radius * 0.85,
              height:      widget.radius * 0.85,
              decoration:  BoxDecoration(
                color:       Colors.white,
                shape:       BoxShape.circle,
                boxShadow:   const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: _busy
                  ? Padding(
                      padding: const EdgeInsets.all(3),
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color:       AppColors.teal,
                      ),
                    )
                  : Icon(
                      Icons.camera_alt_rounded,
                      size:  widget.radius * 0.5,
                      color: AppColors.navy,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
