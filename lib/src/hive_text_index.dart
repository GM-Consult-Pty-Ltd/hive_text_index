// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:text_indexing/text_indexing.dart';
import 'package:text_indexing/type_definitions.dart';

part 'parts/_dictionary.dart';
part 'parts/_k_gram_index.dart';
part 'parts/_postings.dart';
part 'parts/_keyword_postings.dart';

/// A [Hive] based [InvertedIndex] with [AsyncCallbackIndexMixin].
abstract class HiveTextIndex
    with AsyncCallbackIndexMixin
    implements InvertedIndex {
//

  /// Ensure that [Hive] is initialized by calling ``` Hive.init(path);```.
  static Future<HiveTextIndex> hydrate(
    String name, {
    required CollectionSizeCallback collectionSizeLoader,
    required ZoneWeightMap zones,
    required int k,
    required TextAnalyzer analyzer,
    required TokenizingStrategy strategy,
    TokenFilter? tokenFilter,
    NGramRange? nGramRange,
  }) async {
    final retVal = _HiveTextIndexImpl(k, collectionSizeLoader, nGramRange,
        strategy, analyzer, zones, tokenFilter);
    await retVal.init(name);
    return retVal;
  }

  /// A [Hive] based document frequency (Dft) index.
  HiveDictionary get dictionary;

  /// A [Hive] based k-gram index.
  HiveKGramIndex get kGramIndex;

  /// A [Hive] based k-gram index.
  HiveKeywordIndex get keywordIndex;

  /// A [Hive] based k-gram index.
  HivePostingsIndex get postingsIndex;

  /// Closes all the [Hive] boxes used by this index.
  Future<void> clear();

  /// Closes all the [Hive] boxes used by this index.
  Future<void> close();
}

/// Mixin class implements HiveTextIndex.
abstract class HiveTextIndexMixin implements HiveTextIndex {
  //

  @override
  CollectionSizeCallback get dictionaryLengthLoader => dictionary.length;

  @override
  DftMapLoader get dictionaryLoader => dictionary.dictionaryLoader;

  @override
  DftMapUpdater get dictionaryUpdater => dictionary.dictionaryUpdater;

  @override
  KGramsMapLoader get kGramIndexLoader => kGramIndex.kGramIndexLoader;

  @override
  KGramsMapUpdater get kGramIndexUpdater => kGramIndex.kGramIndexUpdater;

  @override
  KeywordPostingsMapLoader get keywordPostingsLoader => keywordIndex.loader;

  @override
  KeywordPostingsMapUpdater get keywordPostingsUpdater => keywordIndex.updater;

  @override
  PostingsMapLoader get postingsLoader => postingsIndex.loader;

  @override
  PostingsMapUpdater get postingsUpdater => postingsIndex.updater;

  @override
  Future<int> get vocabularyLength => dictionary.length();

  @override
  Future<void> close() async {
    await dictionary.dataStore.close();
    await kGramIndex.dataStore.close();
    await postingsIndex.dataStore.close();
    await keywordIndex.dataStore.close();
  }

  @override
  Future<void> clear() async {
    await dictionary.dataStore.clear();
    await kGramIndex.dataStore.clear();
    await postingsIndex.dataStore.clear();
    await keywordIndex.dataStore.clear();
  }
}

/// Extendable base class implementation of [HiveTextIndex].
abstract class HiveTextIndexBase
    with HiveTextIndexMixin, AsyncCallbackIndexMixin {
  /// A const default generative constructor.
  HiveTextIndexBase();

  /// Opens all the [Hive] boxes used by the [HiveTextIndex].
  Future<void> init(String name) async {
    dictionary = HiveDictionary(await Hive.openBox(
      '${name}dictionary',
      // compactionStrategy: compactionStrategy
    ));
    kGramIndex = HiveKGramIndex(await Hive.openBox(
      '${name}kGramIndex',
      // compactionStrategy: compactionStrategy
    ));
    keywordIndex = HiveKeywordIndex(await Hive.openBox(
      '${name}keywordIndex',
      // compactionStrategy: compactionStrategy
    ));
    postingsIndex = HivePostingsIndex(await Hive.openBox(
      '${name}postingsIndex',
    ));
  }

  /// A [Hive] based document frequency (Dft) index.
  @override
  late HiveDictionary dictionary;

  /// A [Hive] based k-gram index.
  @override
  late HiveKGramIndex kGramIndex;

  /// A [Hive] based k-gram index.
  @override
  late HiveKeywordIndex keywordIndex;

  /// A [Hive] based k-gram index.
  @override
  late HivePostingsIndex postingsIndex;
}

/// Implementation class for [HiveTextIndex] unnamed factory.
class _HiveTextIndexImpl extends HiveTextIndexBase {
  /// Private generative constructor.
  _HiveTextIndexImpl(
    this.k,
    this.collectionSizeLoader,
    this.nGramRange,
    this.strategy,
    this.analyzer,
    this.zones,
    this.tokenFilter,
  );

  @override
  final TokenFilter? tokenFilter;

  @override
  final CollectionSizeCallback collectionSizeLoader;

  @override
  final int k;

  @override
  final NGramRange? nGramRange;

  @override
  final TokenizingStrategy strategy;

  @override
  final TextAnalyzer analyzer;

  @override
  final ZoneWeightMap zones;
}
