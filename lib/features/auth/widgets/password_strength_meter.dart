import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  Color get _color {
    switch (_strength) {
      case 0:
      case 1:
        return AppColors.crimson;
      case 2:
        return AppColors.golden;
      case 3:
        return AppColors.sky;
      default:
        return AppColors.teal;
    }
  }

  String get _label {
    switch (_strength) {
      case 0:
        return '';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < _strength ? _color : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildCheck('8+ characters', password.length >= 8),
            const SizedBox(width: 12),
            _buildCheck('Uppercase', RegExp(r'[A-Z]').hasMatch(password)),
            const SizedBox(width: 12),
            _buildCheck('Number', RegExp(r'[0-9]').hasMatch(password)),
            const SizedBox(width: 12),
            _buildCheck('Symbol',
                RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ],
    );
  }

  Widget _buildCheck(String label, bool passed) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 12,
          color: passed ? AppColors.teal : Colors.black26,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: passed ? AppColors.teal : Colors.black38,
          ),
        ),
      ],
    );
  }
}