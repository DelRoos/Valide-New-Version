import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Design reference : iPhone 14 / Android entry-level phone portrait.
/// `.w` / `.h` / `.sp` dans les widgets sont scalés relativement à ce gabarit.
const Size kDesignSize = Size(375, 812);

class ValideApp extends ConsumerWidget {
  const ValideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: kDesignSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        title: 'Valide School',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
