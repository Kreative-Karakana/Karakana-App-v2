import 'package:flutter/material.dart';

import '../../../widgets/common/minimum_tap_target.dart';

class StarRatingInput extends StatelessWidget {
  static const double spacing = 4;

  final int rating;
  final ValueChanged<int> onChanged;

  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        return Padding(
          padding: EdgeInsets.only(right: index < 4 ? spacing : 0),
          child: MinimumTapTarget(
            key: ValueKey('rating-star-$value'),
            semanticsLabel: 'Nyota $value kati ya 5',
            onTap: () => onChanged(value),
            child: Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: const Color(0xFFFFA726),
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}
