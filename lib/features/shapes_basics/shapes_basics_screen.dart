import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// "Shapes Basics" — 12 fundamental shapes drawn with CustomPainter,
/// each with bilingual name, side count, and a real-world example
/// ("a clock face is a circle"). Designed for ages 5-8 picking up
/// geometry vocabulary.
class ShapesBasicsScreen extends ConsumerStatefulWidget {
  const ShapesBasicsScreen({super.key});

  @override
  ConsumerState<ShapesBasicsScreen> createState() =>
      _ShapesBasicsScreenState();
}

class _ShapesBasicsScreenState extends ConsumerState<ShapesBasicsScreen> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? '🔷 الأشكال' : '🔷 Shapes'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: Column(
        children: [
          if (_selected != null)
            _ShapeDetail(shape: _shapes[_selected!], isAr: isAr),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: _shapes.length,
              itemBuilder: (ctx, i) {
                final s = _shapes[i];
                final isSelected = _selected == i;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? s.color.withAlpha(40)
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? s.color : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CustomPaint(
                            painter: _ShapePainter(s.kind, s.color),
                            size: const Size.fromHeight(56),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr ? s.nameAr : s.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeDetail extends StatelessWidget {
  const _ShapeDetail({required this.shape, required this.isAr});
  final _Shape shape;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [shape.color.withAlpha(36), AppColors.accent.withAlpha(16)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shape.color.withAlpha(140)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(painter: _ShapePainter(shape.kind, shape.color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? shape.nameAr : shape.name,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.textDark,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                if (shape.sides > 0)
                  Text(
                    isAr
                        ? '${localizeDigits(shape.sides, arabic: true)} أضلاع'
                        : '${shape.sides} sides',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark.withAlpha(170),
                      fontSize: 12,
                    ),
                  )
                else
                  Text(
                    isAr ? 'لا أضلاع' : 'no sides',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textDark.withAlpha(170),
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  isAr ? shape.exampleAr : shape.example,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Kind {
  circle,
  square,
  rectangle,
  triangle,
  pentagon,
  hexagon,
  octagon,
  oval,
  diamond,
  star,
  heart,
  parallelogram,
}

class _Shape {
  const _Shape({
    required this.kind,
    required this.name,
    required this.nameAr,
    required this.sides,
    required this.example,
    required this.exampleAr,
    required this.color,
  });
  final _Kind kind;
  final String name;
  final String nameAr;
  final int sides; // 0 means "no sides" (circle, oval) or non-polygon
  final String example;
  final String exampleAr;
  final Color color;
}

const List<_Shape> _shapes = [
  _Shape(
    kind: _Kind.circle,
    name: 'Circle',
    nameAr: 'دائرة',
    sides: 0,
    example: 'A clock face is a circle.',
    exampleAr: 'وجه الساعة دائرة.',
    color: AppColors.secondary,
  ),
  _Shape(
    kind: _Kind.square,
    name: 'Square',
    nameAr: 'مربع',
    sides: 4,
    example: 'A Rubik\'s Cube face is a square.',
    exampleAr: 'وجه مكعب روبيك مربع.',
    color: AppColors.accent,
  ),
  _Shape(
    kind: _Kind.rectangle,
    name: 'Rectangle',
    nameAr: 'مستطيل',
    sides: 4,
    example: 'A door is a rectangle.',
    exampleAr: 'الباب مستطيل.',
    color: AppColors.primary,
  ),
  _Shape(
    kind: _Kind.triangle,
    name: 'Triangle',
    nameAr: 'مثلث',
    sides: 3,
    example: 'A slice of pizza is a triangle.',
    exampleAr: 'قطعة البيتزا مثلث.',
    color: AppColors.success,
  ),
  _Shape(
    kind: _Kind.pentagon,
    name: 'Pentagon',
    nameAr: 'خماسي',
    sides: 5,
    example: 'A home-plate in baseball is a pentagon.',
    exampleAr: 'قاعدة الكرة في البيسبول خماسية.',
    color: AppColors.warning,
  ),
  _Shape(
    kind: _Kind.hexagon,
    name: 'Hexagon',
    nameAr: 'سداسي',
    sides: 6,
    example: 'A honeycomb cell is a hexagon.',
    exampleAr: 'خلية النحل سداسية.',
    color: Color(0xFFE57373),
  ),
  _Shape(
    kind: _Kind.octagon,
    name: 'Octagon',
    nameAr: 'ثماني',
    sides: 8,
    example: 'A stop sign is an octagon.',
    exampleAr: 'إشارة «قف» ثمانية.',
    color: AppColors.error,
  ),
  _Shape(
    kind: _Kind.oval,
    name: 'Oval',
    nameAr: 'بيضاوي',
    sides: 0,
    example: 'An egg shape is an oval.',
    exampleAr: 'البيضة شكل بيضاوي.',
    color: Color(0xFFFFB74D),
  ),
  _Shape(
    kind: _Kind.diamond,
    name: 'Diamond',
    nameAr: 'معين',
    sides: 4,
    example: 'A kite frame is a diamond.',
    exampleAr: 'إطار الطائرة الورقية معين.',
    color: Color(0xFF9575CD),
  ),
  _Shape(
    kind: _Kind.star,
    name: 'Star',
    nameAr: 'نجمة',
    sides: 5,
    example: 'A starfish has 5 points like a star.',
    exampleAr: 'نجم البحر له خمس نقاط كالنجمة.',
    color: Color(0xFFFFD54F),
  ),
  _Shape(
    kind: _Kind.heart,
    name: 'Heart',
    nameAr: 'قلب',
    sides: 0,
    example: 'Hearts mean love.',
    exampleAr: 'القلوب ترمز إلى الحب.',
    color: Color(0xFFEF5350),
  ),
  _Shape(
    kind: _Kind.parallelogram,
    name: 'Parallelogram',
    nameAr: 'متوازي أضلاع',
    sides: 4,
    example: 'Many tile patterns use parallelograms.',
    exampleAr: 'كثير من أنماط البلاط تستخدم متوازي الأضلاع.',
    color: Color(0xFF4DB6AC),
  ),
];

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.kind, this.color);
  final _Kind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color.withAlpha(130);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = math.min(w, h) / 2 - 4;

    switch (kind) {
      case _Kind.circle:
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawCircle(Offset(cx, cy), r, stroke);
      case _Kind.square:
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.7, height: r * 1.7);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), stroke);
      case _Kind.rectangle:
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.2);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), stroke);
      case _Kind.triangle:
        _drawPolygon(canvas, fill, stroke, cx, cy, r, 3, -math.pi / 2);
      case _Kind.pentagon:
        _drawPolygon(canvas, fill, stroke, cx, cy, r, 5, -math.pi / 2);
      case _Kind.hexagon:
        _drawPolygon(canvas, fill, stroke, cx, cy, r, 6, 0);
      case _Kind.octagon:
        _drawPolygon(canvas, fill, stroke, cx, cy, r, 8, math.pi / 8);
      case _Kind.oval:
        final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 1.4);
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, stroke);
      case _Kind.diamond:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.7, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.7, cy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case _Kind.star:
        _drawStar(canvas, fill, stroke, cx, cy, r);
      case _Kind.heart:
        _drawHeart(canvas, fill, stroke, cx, cy, r);
      case _Kind.parallelogram:
        final slant = r * 0.3;
        final path = Path()
          ..moveTo(cx - r + slant, cy - r * 0.6)
          ..lineTo(cx + r, cy - r * 0.6)
          ..lineTo(cx + r - slant, cy + r * 0.6)
          ..lineTo(cx - r, cy + r * 0.6)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
    }
  }

  void _drawPolygon(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double cx,
    double cy,
    double r,
    int sides,
    double startAngle,
  ) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = startAngle + i * 2 * math.pi / sides;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawStar(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double cx,
    double cy,
    double r,
  ) {
    final path = Path();
    const points = 5;
    final inner = r * 0.45;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final x = cx + radius * math.cos(a);
      final y = cy + radius * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawHeart(
    Canvas canvas,
    Paint fill,
    Paint stroke,
    double cx,
    double cy,
    double r,
  ) {
    final path = Path();
    final w = r * 1.6;
    final h = r * 1.6;
    final top = cy - h / 2;
    path.moveTo(cx, cy + h / 2);
    path.cubicTo(
      cx - w * 0.9, cy + h * 0.15,
      cx - w * 0.45, top - h * 0.1,
      cx, cy - h * 0.15,
    );
    path.cubicTo(
      cx + w * 0.45, top - h * 0.1,
      cx + w * 0.9, cy + h * 0.15,
      cx, cy + h / 2,
    );
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.kind != kind || old.color != color;
}
