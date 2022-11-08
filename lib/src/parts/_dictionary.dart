// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

part of '../hive_text_index.dart';

/// A [Hive] based document frequency (Dft) index.
class HiveDictionary {
  //

  /// The datastore for the index.
  final Box<int> dataStore;

  /// Default constructor.
  const HiveDictionary(this.dataStore);

  /// The [CollectionSizeCallback] for the index.
  Future<int> length() async => dataStore.length;

  /// The [DftMapLoader] for the index.
  Future<Map<String, int>> dictionaryLoader([Iterable<String>? terms]) async {
    final Map<String, int> retVal = {};
    terms = terms ?? (dataStore.keys.map((e) => e.toString()));
    for (final key in terms) {
      final entry = dataStore.get(key);
      if (entry != null) {
        retVal[key] = entry;
      }
    }
    return retVal;
  }

  /// The [DftMapUpdater] for the index.
  Future<void> dictionaryUpdater(Map<String, int> values) async =>
      dataStore.putAll(values.map((key, value) => MapEntry(key, value)));
}
