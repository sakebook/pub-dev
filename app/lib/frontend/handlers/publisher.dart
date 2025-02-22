// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pub_dev/audit/backend.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../account/backend.dart';
import '../../package/search_adapter.dart';
import '../../publisher/backend.dart';
import '../../search/search_form.dart';
import '../../shared/handlers.dart';
import '../../shared/redis_cache.dart' show cache;
import '../../shared/urls.dart' as urls;
import '../request_context.dart';
import '../templates/listing.dart' show PageLinks;
import '../templates/misc.dart';
import '../templates/publisher.dart';

import 'misc.dart' show formattedNotFoundHandler;

/// Handles requests for GET /create-publisher
Future<shelf.Response> createPublisherPageHandler(shelf.Request request) async {
  if (userSessionData == null) {
    return htmlResponse(renderUnauthenticatedPage());
  }
  return htmlResponse(renderCreatePublisherPage());
}

/// Handles requests for GET /publishers
Future<shelf.Response> publisherListHandler(shelf.Request request) async {
  if (requestContext.uiCacheEnabled) {
    final content = await cache.uiPublisherListPage().get(() async {
      final page = await publisherBackend.listPublishers();
      return renderPublisherListPage(page.publishers!);
    });
    return htmlResponse(content!);
  }

  // no caching for logged-in user
  final page = await publisherBackend.listPublishers();
  final content = renderPublisherListPage(page.publishers!);
  return htmlResponse(content);
}

/// Handles requests for GET /publishers/<publisherId>
Future<shelf.Response> publisherPageHandler(
    shelf.Request request, String publisherId) async {
  checkPublisherIdParam(publisherId);
  return redirectResponse(urls.publisherPackagesUrl(publisherId));
}

/// Handles requests for GET /publishers/<publisherId>/packages [?q=...]
Future<shelf.Response> publisherPackagesPageHandler(
    shelf.Request request, String publisherId) async {
  final searchForm = SearchForm.parse(
    SearchContext.publisher(publisherId),
    request.requestedUri.queryParameters,
  );
  // Redirect in case of empty search query.
  if (request.requestedUri.query == 'q=') {
    return redirectResponse(request.requestedUri.path);
  }

  final isLanding = request.requestedUri.queryParameters.isEmpty;
  if (isLanding && requestContext.uiCacheEnabled) {
    final html = await cache.uiPublisherPackagesPage(publisherId).get();
    if (html != null) {
      return htmlResponse(html);
    }
  }

  final publisher = await publisherBackend.getPublisher(publisherId);
  if (publisher == null) {
    // We may introduce search for publishers (e.g. somebody just mistyped a
    // domain name), but now we just have a formatted error page.
    return formattedNotFoundHandler(request);
  }

  final searchResult = await searchAdapter.search(searchForm);
  final int totalCount = searchResult.totalCount;
  final links = PageLinks(searchForm, totalCount);

  final html = renderPublisherPackagesPage(
    publisher: publisher,
    searchResultPage: searchResult,
    pageLinks: links,
    searchForm: searchForm,
    totalCount: totalCount,
    isAdmin: await publisherBackend.isMemberAdmin(
        publisherId, userSessionData?.userId),
    messageFromBackend: searchResult.message,
  );
  if (isLanding && requestContext.uiCacheEnabled) {
    await cache.uiPublisherPackagesPage(publisherId).set(html);
  }
  return htmlResponse(html);
}

/// Handles requests for GET /publishers/<publisherId>/admin
Future<shelf.Response> publisherAdminPageHandler(
    shelf.Request request, String publisherId) async {
  final publisher = await publisherBackend.getPublisher(publisherId);
  if (publisher == null) {
    // We may introduce search for publishers (e.g. somebody just mistyped a
    // domain name), but now we just have a formatted error page.
    return formattedNotFoundHandler(request);
  }

  if (userSessionData == null) {
    return htmlResponse(renderUnauthenticatedPage());
  }
  final isAdmin = await publisherBackend.isMemberAdmin(
    publisherId,
    userSessionData!.userId,
  );
  if (!isAdmin) {
    return htmlResponse(renderUnauthorizedPage());
  }

  return htmlResponse(renderPublisherAdminPage(
    publisher: publisher,
    members: await publisherBackend.listPublisherMembers(publisherId),
  ));
}

/// Handles requests for GET /publishers/<publisherId>/activity-log
Future<shelf.Response> publisherActivityLogPageHandler(
    shelf.Request request, String publisherId) async {
  final publisher = await publisherBackend.getPublisher(publisherId);
  if (publisher == null) {
    // We may introduce search for publishers (e.g. somebody just mistyped a
    // domain name), but now we just have a formatted error page.
    return formattedNotFoundHandler(request);
  }

  if (userSessionData == null) {
    return htmlResponse(renderUnauthenticatedPage());
  }
  final isAdmin = await publisherBackend.isMemberAdmin(
    publisherId,
    userSessionData!.userId,
  );
  if (!isAdmin) {
    return htmlResponse(renderUnauthorizedPage());
  }

  final before = auditBackend.parseBeforeQueryParameter(
      request.requestedUri.queryParameters['before']);
  final activities = await auditBackend.listRecordsForPublisher(
    publisherId,
    before: before,
  );
  return htmlResponse(renderPublisherActivityLogPage(
    publisher: publisher,
    activities: activities,
  ));
}
