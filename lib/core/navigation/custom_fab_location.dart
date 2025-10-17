import 'package:flutter/material.dart';

/// Custom FAB location that positions the button
/// slightly above the bottom navigation bar
class CustomFABLocation extends FloatingActionButtonLocation {
  final double offsetY;
  final double offsetX;

  const CustomFABLocation({
    this.offsetY = -8, // Move up by 8px from default
    this.offsetX = 0,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Calculate default end float position
    final double fabX = scaffoldGeometry.scaffoldSize.width - 
                        scaffoldGeometry.floatingActionButtonSize.width - 16;
    
    final double fabY = scaffoldGeometry.scaffoldSize.height -
                        scaffoldGeometry.floatingActionButtonSize.height -
                        scaffoldGeometry.minInsets.bottom - 
                        16 + offsetY; // Apply offset

    return Offset(fabX + offsetX, fabY);
  }
}