import 'package:flutter/material.dart';
import 'package:get/get.dart';

T getLanguage<T>() {
  final instance = Localizations.of<T>(Get.context!, T);
  assert(instance != null, 'No instance of $T ');
  return instance!;
}
