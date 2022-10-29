import 'dart:math';

import 'package:english_words/english_words.dart';

List<String> generateWords(int max, Random rand) {
  final words = <String>[];
  for (var i = 0; i < rand.nextInt(max); i++) {
    words.add(nouns[rand.nextInt(nouns.length)]);
  }
  return words;
}
