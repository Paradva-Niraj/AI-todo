import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isPortrait = mq.orientation == Orientation.portrait;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: isPortrait ? 36 : 18, horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (onBack != null)
                  Align(alignment: Alignment.topLeft, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back))),
                Hero(tag: 'logo', child: _buildLogo(context)),
                const SizedBox(height: 18),
                Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 20),
                Card(elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20), child: child)),
                const SizedBox(height: 14),
                Text('By continuing you agree to our Terms & Privacy.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withOpacity(0.12)),
      child: Icon(Icons.task_alt, size: 52, color: Theme.of(context).colorScheme.primary),
    );
  }
}