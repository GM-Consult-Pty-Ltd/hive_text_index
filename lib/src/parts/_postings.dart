// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

part of '../hive_text_index.dart';

/// A [Hive] based keyword index.
class HivePostingsIndex {
//

  /// The [Hive] dataStore for this index
  final Box<String> dataStore;

  /// Default constructor.
  const HivePostingsIndex(this.dataStore);

  /// The [PostingsMapLoader] for the index.
  Future<PostingsMap> loader(Iterable<String> keywords) async {
    final PostingsMap retVal = {};

    for (final key in keywords) {
      final entry = dataStore.get(key);
      if (entry != null) {
        final value = (jsonDecode(entry) as Map).map((key, value) => MapEntry(
            key.toString(),
            (value as Map).map((k, v) =>
                MapEntry(k.toString(), (List<int>.from(v as Iterable))))));
        retVal[key] = value;
      }
    }
    return retVal;
  }

  //Map<String, Map<String, Map<String, List<int>>>>

  /// The [PostingsMapUpdater] for the index.
  Future<void> updater(PostingsMap values) => dataStore
      .putAll(values.map((key, value) => MapEntry(key, jsonEncode(value))));
}
