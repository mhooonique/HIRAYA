import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

const _kValidGreen = Color(0xFF1A8B5A);

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final bool readOnly;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  bool _obscure = true;
  int _charCount = 0;
  bool _isFocused = false;
  bool _isValid = false;
  bool _isDirty = false;
  late final FocusNode _focusNode;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  void _onTextChanged() {
    if (!mounted) return;
    final text = widget.controller.text;
    final valid = widget.validator != null
        ? widget.validator!(text) == null && text.isNotEmpty
        : text.isNotEmpty;
    setState(() {
      _charCount = text.length;
      _isValid   = valid;
      _isDirty   = true;
    });
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _entranceFade  = CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOutCubic);
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Color get _labelColor {
    if (_isDirty && _isValid) return _kValidGreen;
    if (_isFocused)           return AppColors.teal;
    return AppColors.navy;
  }

  Color get _glowColor {
    if (_isDirty && _isValid) return _kValidGreen;
    return AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated label — navy → teal on focus, green when valid
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: _isDirty && _isValid
                    ? const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: _kValidGreen,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Outer glow wrapper — teal or green blooms on focus/valid
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: (_isFocused || (_isDirty && _isValid))
                ? [
                    BoxShadow(
                      color: _glowColor.withValues(alpha: 0.16),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            maxLength: widget.maxLength,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.darkGray,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black26,
              ),
              counterText: widget.maxLength != null &&
                      _charCount > (widget.maxLength! * 0.7).toInt()
                  ? '$_charCount/${widget.maxLength}'
                  : '',
              prefixIcon: widget.prefix,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: _isFocused ? AppColors.teal : Colors.black38,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : (_isDirty && _isValid
                      ? const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: _kValidGreen,
                        )
                      : widget.suffix),
              filled: true,
              fillColor: _isDirty && _isValid
                  ? _kValidGreen.withValues(alpha: 0.03)
                  : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isDirty && _isValid
                      ? _kValidGreen
                      : AppColors.lightGray,
                  width: _isDirty && _isValid ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _isDirty && _isValid ? _kValidGreen : AppColors.teal,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.crimson, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.crimson, width: 2),
              ),
            ),
          ),
        ),
      ],
    ),
      ),
    );
  }
}