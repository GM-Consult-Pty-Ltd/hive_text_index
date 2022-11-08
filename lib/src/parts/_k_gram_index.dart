// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

part of '../hive_text_index.dart';

/// A [Hive] based k-gram index.
class HiveKGramIndex {
//

  /// The [Hive] dataStore for this index
  final Box<String> dataStore;

  /// Default constructor.
  const HiveKGramIndex(this.dataStore);

  /// The [KGramsMapLoader] for the index.
  Future<Map<String, Set<String>>> kGramIndexLoader(
      [Iterable<String>? terms]) async {
    final Map<String, Set<String>> retVal = {};
    terms = terms ?? (dataStore.keys.map((e) => e.toString()));
    for (final key in terms) {
      final entry = dataStore.get(key);
      if (entry != null) {
        final value = List<String>.from(jsonDecode(entry) as List).toSet();
        retVal[key] = value;
      }
    }
    return retVal;
  }

  /// The [KGramsMapUpdater] for the index.
  Future<void> kGramIndexUpdater(Map<String, Set<String>> values) =>
      dataStore.putAll(values
          .map((key, value) => MapEntry(key, jsonEncode(value.toList()))));
}
