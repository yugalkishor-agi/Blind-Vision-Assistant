import 'package:flutter/material.dart';
import 'semantic_button_registry.dart';

class SemanticMaterialButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;
  final String? tooltip;

  const SemanticMaterialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  State<SemanticMaterialButton> createState() => _SemanticMaterialButtonState();
}

class _SemanticMaterialButtonState extends State<SemanticMaterialButton> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    SemanticButtonRegistry.register(widget.label, _key);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      enabled: widget.onPressed != null,
      child: Tooltip(
        message: widget.tooltip ?? widget.label,
        child: Material(
          key: _key,
          color: widget.color ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(widget.icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
