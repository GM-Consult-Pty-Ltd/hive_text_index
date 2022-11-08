// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

part of '../hive_text_index.dart';

/// A [Hive] based keyword index.
class HiveKeywordIndex {
//

  /// The [Hive] dataStore for this index
  final Box<String> dataStore;

  /// Default constructor.
  const HiveKeywordIndex(this.dataStore);

  /// The [KeywordPostingsMapLoader] for the index.
  Future<Map<String, Map<String, double>>> loader(
      Iterable<String> keywords) async {
    final Map<String, Map<String, double>> retVal = {};

    for (final key in keywords) {
      final entry = dataStore.get(key);
      if (entry != null) {
        final value = (jsonDecode(entry) as Map)
            .map((key, value) => MapEntry(key.toString(), value as double));
        retVal[key] = value;
      }
    }
    return retVal;
  }

  /// The [KeywordPostingsMapUpdater] for the index.
  Future<void> updater(Map<String, Map<String, double>> values) => dataStore
      .putAll(values.map((key, value) => MapEntry(key, jsonEncode(value))));
}
