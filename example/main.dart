// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_app_links/otel_app_links.dart';

/// Traces app-links calls with OpenTelemetry.
///
/// `otel_app_links` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each app-links call in
/// [tracedAppLinks]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'app-links-example');

  // Wraps an app-links call in a CONSUMER span (incoming link).
  final appLinksId = await tracedAppLinks<String>(
    operation: 'create',
    invoke: () async {
      // Make the app-links call here, then report what it returned.
      const id = 'app_links_8f3a2c';
      return const AppLinksCallResult(
          value: id,
          result: AppLinksResult(
              linkKind: 'universal_link',
              scheme: 'https',
              host: 'api.example.com',
              path: '/v1/orders',
              queryParamCount: 3,
              fragmentPresent: true,
              platform: 'ios',
              coldStart: true,
              referrerPackage: 'com.android.chrome',
              referrerUrl: 'https://api.example.com/v1/resource',
              deferredDeepLink: true,
              universalLinkMatched: true,
              androidAppLinksVerified: true,
              errorCode: 'unsupported_scheme'));
    },
  );
  OTelLog.info('tracedAppLinks create returned $appLinksId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAppLinksInstrumentationAsync.
  await runWithoutAppLinksInstrumentationAsync(
    () => tracedAppLinks<String>(
      operation: 'create',
      invoke: () async {
        const id = 'app_links_8f3a2c';
        return const AppLinksCallResult(
            value: id,
            result: AppLinksResult(
                linkKind: 'universal_link',
                scheme: 'https',
                host: 'api.example.com',
                path: '/v1/orders',
                queryParamCount: 3,
                fragmentPresent: true,
                platform: 'ios',
                coldStart: true,
                referrerPackage: 'com.android.chrome',
                referrerUrl: 'https://api.example.com/v1/resource',
                deferredDeepLink: true,
                universalLinkMatched: true,
                androidAppLinksVerified: true,
                errorCode: 'unsupported_scheme'));
      },
    ),
  );

  await OTel.shutdown();
}
