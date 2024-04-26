import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    super.key,
    this.size = 64,
    required this.icon,
    this.color = Colors.white,
    required this.press,
  });

  final double size;
  final Icon icon;
  final Color color;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      // ignore: deprecated_member_use
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.all(15 / 64 * size),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
        ),
        onPressed: press,
        child: icon,
      ),
    );
  }
}
