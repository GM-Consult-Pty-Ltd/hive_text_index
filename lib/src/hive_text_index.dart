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
class HiveTextIndex
    with InvertedIndexMixin, AsyncCallbackIndexMixin
    implements InvertedIndex {
//

  /// Ensure that [Hive] is initialized by calling ``` Hive.init(path);```.
  static Future<HiveTextIndex> hydrate(
    String name, {
    required CollectionSizeCallback collectionSizeLoader,
    required ZoneWeightMap zones,
    required int k,

    // required bool Function(int, int)? compactionStrategy,
    required TextAnalyzer analyzer,
    required TokenizingStrategy strategy,
    TokenFilter? tokenFilter,
    NGramRange? nGramRange,
  }) async {
    final dictionary = HiveDictionary(await Hive.openBox(
      '${name}dictionary',
      // compactionStrategy: compactionStrategy
    ));
    final kGramIndex = HiveKGramIndex(await Hive.openBox(
      '${name}kGramIndex',
      // compactionStrategy: compactionStrategy
    ));
    final keywordIndex = HiveKeywordIndex(await Hive.openBox(
      '${name}keywordIndex',
      // compactionStrategy: compactionStrategy
    ));
    final postingsIndex = HivePostingsIndex(await Hive.openBox(
      '${name}postingsIndex',
      // compactionStrategy: compactionStrategy
    ));
    return HiveTextIndex._(
        k,
        collectionSizeLoader,
        nGramRange,
        strategy,
        analyzer,
        analyzer.keywordExtractor,
        zones,
        dictionary,
        kGramIndex,
        keywordIndex,
        postingsIndex,
        tokenFilter);
  }

  /// Closes all the [Hive] boxes used by this index.
  Future<void> close() async {
    await dictionary.dataStore.close();
    await kGramIndex.dataStore.close();
    await postingsIndex.dataStore.close();
    await keywordIndex.dataStore.close();
  }

  @override
  final int k;

  @override
  final NGramRange? nGramRange;

  @override
  final TokenizingStrategy strategy;

  @override
  final TextAnalyzer analyzer;

  @override
  final KeywordExtractor keywordExtractor;

  @override
  final ZoneWeightMap zones;

  /// A [Hive] based document frequency (Dft) index.
  final HiveDictionary dictionary;

  /// A [Hive] based k-gram index.
  final HiveKGramIndex kGramIndex;

  /// A [Hive] based k-gram index.
  final HiveKeywordIndex keywordIndex;

  /// A [Hive] based k-gram index.
  final HivePostingsIndex postingsIndex;

  /// Private generative constructor.
  const HiveTextIndex._(
    this.k,
    this.collectionSizeLoader,
    this.nGramRange,
    this.strategy,
    this.analyzer,
    this.keywordExtractor,
    this.zones,
    this.dictionary,
    this.kGramIndex,
    this.keywordIndex,
    this.postingsIndex,
    this.tokenFilter,
  );

  @override
  final CollectionSizeCallback collectionSizeLoader;

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
  final TokenFilter? tokenFilter;
}
