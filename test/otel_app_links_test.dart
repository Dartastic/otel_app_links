// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_app_links/otel_app_links.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_app_links-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('getInitialAppLink records universal link + cold start', () async {
    await tracedAppLinks<String>(
      operation: 'getInitialAppLink',
      invoke: () async => const AppLinksCallResult(
        value: 'ok',
        result: AppLinksResult(
          linkKind: 'universal_link',
          scheme: 'https',
          host: 'app.example.com',
          path: '/products/42',
          queryParamCount: 2,
          platform: 'ios',
          coldStart: true,
          universalLinkMatched: true,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('app_links getInitialAppLink')!);
    expect(a['app_links.link.kind'], 'universal_link');
    expect(a['app_links.cold_start'], true);
    expect(a['app_links.ios.universal_link_matched'], true);
  });

  test('Android App Links unverified host sets nothing but is recorded',
      () async {
    await tracedAppLinks<String>(
      operation: 'linkStream',
      invoke: () async => const AppLinksCallResult(
        value: 'ok',
        result: AppLinksResult(
          linkKind: 'app_link',
          scheme: 'https',
          host: 'untrusted.example',
          platform: 'android',
          androidAppLinksVerified: false,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('app_links linkStream')!);
    expect(a['app_links.android.verified'], false);
  });

  test('verification_failed sets span error', () async {
    await tracedAppLinks<String>(
      operation: 'getInitialAppLink',
      invoke: () async => const AppLinksCallResult(
        value: 'ok',
        result: AppLinksResult(errorCode: 'verification_failed'),
      ),
    );
    expect(
      spans.findSpanByName('app_links getInitialAppLink')!.status,
      SpanStatusCode.Error,
    );
  });

  test('span kind is CONSUMER (incoming link)', () async {
    await tracedAppLinks<String>(
      operation: 'getInitialAppLink',
      invoke: () async => const AppLinksCallResult(
        value: 'ok',
        result: AppLinksResult(linkKind: 'universal_link'),
      ),
    );
    expect(
      spans.findSpanByName('app_links getInitialAppLink')!.kind,
      SpanKind.consumer,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutAppLinksInstrumentationAsync(() async {
      await tracedAppLinks<String>(
        operation: 'getLatestAppLink',
        invoke: () async => const AppLinksCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('app_links '), isEmpty);
  });
}
