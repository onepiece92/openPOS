import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/country_default.dart';

class CountryRepository {
  static List<CountryDefault>? _cache;

  static Future<List<CountryDefault>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/locales/country_defaults.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list.map(CountryDefault.fromJson).toList();
    return _cache!;
  }
}
