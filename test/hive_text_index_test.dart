// Copyright ©2022, GM Consult (Pty) Ltd.
// BSD 3-Clause License
// All rights reserved

// change this value to suit your tests and de-bugging needs
@Timeout(Duration(minutes: 90))

import 'package:hive/hive.dart';
import 'package:hive_text_index/hive_text_index.dart';
import 'package:test/test.dart';
import 'package:gmconsult_dev/gmconsult_dev.dart';
import 'package:text_indexing/text_indexing.dart';
import 'package:text_indexing/extensions.dart';
// import 'package:text_analysis/implementation.dart';
import 'dart:io';
import 'package:text_indexing/type_definitions.dart';
import 'hashtag_analyzer.dart';

String get kPath => '${Directory.current.path}\\dev\\data';

TextAnalyzer get kAnalyzer => HashTagAnalyzer();

void main() {
  group('A group of tests', () {
    test('JsonDataService.hashtags', (() async {
//   //

      Hive.init(kPath);

      final results = <Map<String, dynamic>>[];

      final service = await hashtagsService;

      // final keys = service.dataStore.keys.map((e) => e.toString()).toList();

      results.addAll(
          (await service.batchRead(['Apple', 'Tesla', 'Intel', 'Alphabet']))
              .values);

      Console.out(
          title: 'HASHTAGS',
          results: results,
          fields: ['id', 'hashTag', 'name', 'timestamp']);

      await service.close();
    }));

    test('Query terms', (() async {
//   //

      Hive.init(kPath);

      final service = await hashtagsService;

      Future<int> collectionSizeLoader() async => service.dataStore.length;

      final index = await hiveIndex(collectionSizeLoader);
      // final postingsCount = index.postingsIndex.dataStore.length;
      // final dftCount = index.postingsIndex.dataStore.length;
      // final keywordsCount = index.keywordIndex.dataStore.length;
      // final kgramsCount = index.kGramIndex.dataStore.length;

      // final keyWords = index.keywordIndex.dataStore.keys;
      // for (final keyword in keyWords) {
      //   print(keyword);
      // }

      // final kw = 'dollar';

      // final postingsBox = index.keywordIndex.dataStore;
      // final posting = postingsBox.get(kw);
      // print('$kw: $posting');

      // final kwBox = index.keywordIndex.dataStore;
      // final kwposting = kwBox.get(kw);
      // print('$kw: $kwposting');
      // });

      final terms = [
        '3M',
        'MMM',
        'Apple inc',
        'AAPL',
        'Tesla',
        'Intel',
        'Alphabet'
      ];

      await Future.forEach(terms, (String term) async {
        final tokenTerms = (await index.analyzer.tokenizer(term)).terms;
        if (tokenTerms.isNotEmpty) {
          final qt = tokenTerms.first;
          final service = await hashtagsService;
          final kGrams = qt.kGrams();
          final dFtMap = await index.getDictionary(tokenTerms);
          final keywordPostings = await index.getKeywordPostings(tokenTerms);
          final kGramsMap = await index.getKGramIndex(kGrams);
          var nKgramPostings = 0;
          for (final e in kGramsMap.entries) {
            nKgramPostings += e.value.length;
          }
          final postings = await index.getPostings(tokenTerms);
          final stocks = postings[qt];
          if (stocks != null &&
              dFtMap.isNotEmpty &&
              stocks.isNotEmpty &&
              keywordPostings.isNotEmpty &&
              kGramsMap.isNotEmpty) {
            final key = stocks.keys.first;
            final stock = await service.read(key);
            final stockName = stock?['name'] ?? '';
            final results = [
              {'Item': 'Term', 'Value': qt},
              {'Item': 'Stock', 'Value': stockName},
              {
                'Item': 'dFt',
                'Value': dFtMap.isEmpty ? '' : dFtMap.values.first
              },
              {
                'Item': 'N Keyword postings',
                'Value': keywordPostings.isEmpty
                    ? ''
                    : keywordPostings.values.first.length
              },
              {
                'Item': 'N postings',
                'Value': postings.isEmpty ? '' : postings.values.first.length
              },
              {'Item': 'N k-gram postings', 'Value': nKgramPostings},
            ];

            Console.out(
              title: 'HASHTAGS',
              results: results,
              // fields: ['Item', 'Value']
            );
          }
        }
      });

      await service.close();
      await index.dispose();
    }));

    test('Index hashtags', () async {
      Hive.init(kPath);
      final service = await hashtagsService;
      Future<int> collectionSizeLoader() async => service.dataStore.length;
      final iMindex = await inMemoryIndex(service.dataStore.length);
      // final indexer = TextIndexer(iMindex);
      final keys = service.dataStore.keys.map((e) => e.toString()).toList();
      var i = 0;
      final start = DateTime.now();
      // keys = keys.sublist(16600);
      // PostingsMap lastPostingsMap = {};
      await Future.forEach(keys, (String key) async {
        final json = await service.read(key);
        if (json != null) {
          final name = json['name'].toString().toLowerCase();
          if (name.contains('intel corp')) {
            print(json);
          }
          await iMindex.indexJson(key, json,
              tokenFilter: HashTagAnalyzer.kFilterTokens);
        }
        final l = await iMindex.vocabularyLength;

        i++;
        if (i.remainder(100) == 0) {
          final dT = DateTime.now().difference(start).inSeconds;
          print('Indexed $i hashTags in ${dT.toStringAsFixed(0)} seconds. '
              'Found $l terms.');
          // print(lastPostingsMap.keys);
        }
      });
      final index = await hiveIndex(collectionSizeLoader);
      await index.clear();
      await index.upsertDictionary(iMindex.dictionary);
      await index.upsertPostings(iMindex.postings);
      await index.upsertKGramIndex(iMindex.kGramIndex);
      await index.upsertKeywordPostings(iMindex.keywordPostings);
      await service.close();

      await index.dispose();
    });
  });
}

bool compactionStrategy(int entries, int deleted) {
  // if (entries.remainder(100) == 0) {
  //   // final dT = DateTime.now().difference(start).inSeconds;
  //   print('Box has $entries entries and $deleted deleted entries.');
  // }
  if (deleted > 10000) {
    print(
        'Box has $entries entries and $deleted deleted entries. Attempting compact');

    return true;
  }
  return false;
}

Future<HiveTextIndex> hiveIndex(
    CollectionSizeCallback collectionSizeLoader) async {
  return await HiveTextIndex.hydrate(HashTagAnalyzer.kIndexName,
      collectionSizeLoader: collectionSizeLoader,
      analyzer: kAnalyzer,
      nGramRange: HashTagAnalyzer.kNGramRange,
      k: HashTagAnalyzer.kK,
      zones: HashTagAnalyzer.kZones);
}

Future<InMemoryIndex> inMemoryIndex(int collectionSize) async {
  return InMemoryIndex(
      collectionSize: collectionSize,
      analyzer: kAnalyzer,
      nGramRange: HashTagAnalyzer.kNGramRange,
      k: HashTagAnalyzer.kK,
      zones: HashTagAnalyzer.kZones);
}

// class TestIndexer extends TextIndexerBase {
//   @override
//   final HiveTextIndex index;

//   TestIndexer(this.index, this.dataService);

//   final JsonDataService dataService;
// }

// TextIndexer indexer(HiveTextIndex index) => TextIndexer(index);

/// Hydrates a [JsonDataService] with a large dataset of securities.
Future<JsonDataService<Box<String>>> get securitiesService async {
  Hive.init(kPath);
  final Box<String> dataStore = await Hive.openBox('securities');
  return HiveJsonService(dataStore);
}

/// Hydrates a [JsonDataService] with a large dataset of securities.
Future<JsonDataService<Box<String>>> get hashtagsService async {
  final Box<String> dataStore = await Hive.openBox('hashtags');
  return HiveJsonService(dataStore);
}
