import 'package:flutter/material.dart';

class AnimatedSubmitButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final IconData? icon;

  const AnimatedSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
  });

  @override
  State<AnimatedSubmitButton> createState() => _AnimatedSubmitButtonState();
}

class _AnimatedSubmitButtonState extends State<AnimatedSubmitButton> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedSubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        final scale = 1.0 - (t * 0.06);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: FilledButton.tonalIcon(
        onPressed: widget.loading ? null : widget.onPressed,
        icon: widget.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(widget.icon ?? Icons.check),
        label: Text(widget.label),
      ),
    );
  }
}