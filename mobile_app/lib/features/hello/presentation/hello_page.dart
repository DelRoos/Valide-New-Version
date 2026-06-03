import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';

class HelloPage extends ConsumerWidget {
  const HelloPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetingTarget = ref.watch(helloProvider);
    return Scaffold(
      body: Center(
        child: Text(
          'Hello $greetingTarget',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
