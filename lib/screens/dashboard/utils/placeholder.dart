// TODO Implement this library.

import 'package:flutter/material.dart';

class PlaceholderImage extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const PlaceholderImage({
    Key? key,
    required this.width,
    required this.height,
    this.color = const Color(0xFFCCCCCC),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.image,
          size: width * 0.5,
          color: color,
        ),
      ),
    );
  }
}