import 'package:flutter/material.dart';

class EmployerWorkersScreen extends StatelessWidget {
  const EmployerWorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Browse Workers', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        centerTitle: true,
        backgroundColor: theme.cardColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.person_search_outlined, size: 64, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Looking for talent?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'This feature is coming soon! You will be able to search and message skilled Karigars directly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
