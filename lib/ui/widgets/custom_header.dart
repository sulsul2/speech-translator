import 'package:flutter/material.dart';
import 'package:speech_translator/shared/theme.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final IconData leftIcon;
  final IconData rightIcon;
  final Color color;

  const CustomHeader({
    super.key,
    required this.title,
    required this.leftIcon,
    required this.rightIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 56,
      right: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              leftIcon,
              color: color,
              size: 32,
            ),
          ),
          Text(
            title,
            style: h3Text.copyWith(color: color),
          ),
          Icon(
            rightIcon,
            color: color,
            size: 32,
          ),
        ],
      ),
    );
  }
}
