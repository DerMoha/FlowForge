import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../state/ink_state.dart';

class FloatingToolPalette extends StatelessWidget {
  const FloatingToolPalette({super.key});

  static const _tools = [
    (InkTool.pen, Icons.edit, 'Pen'),
    (InkTool.highlighter, Icons.highlight, 'Highlighter'),
    (InkTool.eraser, Icons.auto_fix_normal, 'Eraser'),
  ];

  static const _colors = [
    Colors.black,
    Color(0xFF1A237E), // Dark blue
    Color(0xFF0D47A1), // Blue
    Color(0xFF1B5E20), // Green
    Color(0xFFB71C1C), // Red
    Color(0xFFE65100), // Orange
    Color(0xFF4A148C), // Purple
  ];

  @override
  Widget build(BuildContext context) {
    final inkState = context.watch<InkState>();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tool buttons
            ..._tools.map((t) => _ToolButton(
                  tool: t.$1,
                  icon: t.$2,
                  label: t.$3,
                  isSelected: inkState.tool == t.$1,
                  onTap: () => inkState.setTool(t.$1),
                )),
            const Divider(height: 16),
            // Color picker (hidden for eraser)
            if (inkState.tool != InkTool.eraser) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _colors.map((c) => _ColorDot(
                      color: c,
                      isSelected: inkState.color.toARGB32() == c.toARGB32(),
                      onTap: () => inkState.setColor(c),
                    )).toList(),
              ),
              const SizedBox(height: 8),
              // Width slider
              SizedBox(
                width: 120,
                child: Slider(
                  value: inkState.strokeWidth,
                  min: 0.5,
                  max: 10.0,
                  divisions: 19,
                  label: inkState.strokeWidth.toStringAsFixed(1),
                  onChanged: inkState.setStrokeWidth,
                ),
              ),
            ],
            const Divider(height: 16),
            // Undo/Redo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: inkState.canUndo ? inkState.undo : null,
                  tooltip: 'Undo',
                  iconSize: 20,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: const Icon(Icons.redo, size: 20),
                  onPressed: inkState.canRedo
                      ? () => inkState.redo()
                      : null,
                  tooltip: 'Redo',
                  iconSize: 20,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tool,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final InkTool tool;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
