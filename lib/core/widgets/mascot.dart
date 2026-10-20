import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MascotMood {
  calm('blob_sage'),
  happy('blob_coral'),
  thinking('blob_peri'),
  sleepy('blob_ice');

  MascotMood(this.file);
  final String file;
}

/// Original blob-style mascots. All illustration use goes through this widget
/// so the art can be swapped in one place.
class Mascot extends StatelessWidget {
  const Mascot({this.mood = MascotMood.calm, this.size = 48, super.key});

  final MascotMood mood;
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/illustrations/${mood.file}.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
