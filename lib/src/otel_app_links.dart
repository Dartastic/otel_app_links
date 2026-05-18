// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_app_links_suppression.dart';

const _tracerName = 'dartastic_otel_libs_app_links';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class AppLinksResult {
  const AppLinksResult({
    this.linkKind,
    this.scheme,
    this.host,
    this.path,
    this.queryParamCount,
    this.fragmentPresent,
    this.platform,
    this.coldStart,
    this.referrerPackage,
    this.referrerUrl,
    this.deferredDeepLink,
    this.universalLinkMatched,
    this.androidAppLinksVerified,
    this.errorCode,
  });

  /// `universal_link` (iOS), `app_link` (Android), `custom_scheme`,
  /// `deferred_deep_link`.
  final String? linkKind;

  /// `https`, `myapp`, etc.
  final String? scheme;
  final String? host;
  final String? path;

  final int? queryParamCount;
  final bool? fragmentPresent;

  /// `ios`, `android`, `web`, `macos`, `windows`, `linux`.
  final String? platform;

  /// Link launched the app from a cold start (not warm resume).
  final bool? coldStart;

  /// Android referrer package (`com.android.chrome`, ...).
  final String? referrerPackage;

  /// Referrer URL where available (web, search engines).
  final String? referrerUrl;

  /// Link was resolved after install (Play Install Referrer / web fallback).
  final bool? deferredDeepLink;

  /// iOS Universal Link successfully matched apple-app-site-association.
  final bool? universalLinkMatched;

  /// Android App Link verification status (digital asset links verified).
  final bool? androidAppLinksVerified;

  /// `unsupported_scheme`, `verification_failed`, `parse_error`,
  /// `host_not_allowed`, `no_handler`.
  final String? errorCode;
}

class AppLinksCallResult<T> {
  const AppLinksCallResult({required this.value, this.result});
  final T value;
  final AppLinksResult? result;
}

/// Wraps an app-links call in a CONSUMER span (incoming link).
/// [operation] is one of `getInitialAppLink`, `getInitialLink`,
/// `getLatestAppLink`, `onAppLink`, `linkStream`, `uriLinkStream`,
/// `stringLinkStream`.
Future<T> tracedAppLinks<T>({
  required String operation,
  required Future<AppLinksCallResult<T>> Function() invoke,
}) async {
  if (appLinksInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'app_links',
    'rpc.method': operation,
    'app_links.operation': operation,
  };

  final span = _tracer().startSpan(
    'app_links $operation',
    kind: SpanKind.consumer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.linkKind != null) {
        extras.add(OTel.attributeString('app_links.link.kind', res.linkKind!));
      }
      if (res.scheme != null) {
        extras.add(OTel.attributeString('app_links.scheme', res.scheme!));
      }
      if (res.host != null) {
        extras.add(OTel.attributeString('app_links.host', res.host!));
      }
      if (res.path != null) {
        extras.add(OTel.attributeString('app_links.path', res.path!));
      }
      if (res.queryParamCount != null) {
        extras.add(OTel.attributeInt(
          'app_links.query.param_count',
          res.queryParamCount!,
        ));
      }
      if (res.fragmentPresent != null) {
        extras.add(OTel.attributeBool(
          'app_links.fragment.present',
          res.fragmentPresent!,
        ));
      }
      if (res.platform != null) {
        extras.add(OTel.attributeString('app_links.platform', res.platform!));
      }
      if (res.coldStart != null) {
        extras.add(OTel.attributeBool(
          'app_links.cold_start',
          res.coldStart!,
        ));
      }
      if (res.referrerPackage != null) {
        extras.add(OTel.attributeString(
          'app_links.referrer.package',
          res.referrerPackage!,
        ));
      }
      if (res.referrerUrl != null) {
        extras.add(OTel.attributeString(
          'app_links.referrer.url',
          res.referrerUrl!,
        ));
      }
      if (res.deferredDeepLink != null) {
        extras.add(OTel.attributeBool(
          'app_links.deferred',
          res.deferredDeepLink!,
        ));
      }
      if (res.universalLinkMatched != null) {
        extras.add(OTel.attributeBool(
          'app_links.ios.universal_link_matched',
          res.universalLinkMatched!,
        ));
      }
      if (res.androidAppLinksVerified != null) {
        extras.add(OTel.attributeBool(
          'app_links.android.verified',
          res.androidAppLinksVerified!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'app_links.error.code',
          res.errorCode!,
        ));
        span.setStatus(SpanStatusCode.Error, 'app_links ${res.errorCode}');
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
