import 'dart:async';

import 'package:gql/language.dart' as gql_lang;
import 'package:graphql/client.dart';

import '../../../services/offline_mode/network_aware/network_aware_api_mixin.dart';

class GraphQLConnector with NetworkAwareApiMixin {
  GraphQLConnector(this.client);

  final GraphQLClient client;

  @override
  String get keyCacheLocal => 'shopify-graphql';

  Future<QueryResult> query(QueryOptions options, {bool useCache = true}) =>
      callApi(
        () async => await client.query(options),
        key: 'query',
        useCache: useCache,
        keys: [options.variables, gql_lang.printNode(options.document)],
      );

  Future<QueryResult> mutate(MutationOptions options, {bool useCache = true}) =>
      callApi(
        () async => await client.mutate(options),
        key: 'mutate',
        useCache: useCache,
        keys: [options.variables, gql_lang.printNode(options.document)],
      );
}
