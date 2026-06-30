// Page de showcase des composants contenu (debug uniquement).
// Route : /_showcase

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

class ContentShowcasePage extends StatelessWidget {
  const ContentShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Content Showcase'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Showcase — à implémenter'),
      ),
    );
  }
}
