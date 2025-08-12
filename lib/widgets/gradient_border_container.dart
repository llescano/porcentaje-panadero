import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? innerPadding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GradientBorderContainer({
    required this.child,
    this.width,
    this.height,
    this.innerPadding,
    this.margin,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: const EdgeInsets.all(2.5), // This is the border width
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BakeryColors.carameloSuave, BakeryColors.trigoDorado],
            begin: Alignment( -1, -1),
            end: Alignment(1, 1),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: BakeryColors.maderaTostada.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: innerPadding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BakeryColors.panRecienHorneado,
            borderRadius: BorderRadius.circular(17.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
