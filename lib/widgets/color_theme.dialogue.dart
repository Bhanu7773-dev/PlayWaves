import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorThemeDialog extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final ValueChanged<Color> onPrimaryColorChanged;
  final ValueChanged<Color> onSecondaryColorChanged;

  const ColorThemeDialog({
    Key? key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onPrimaryColorChanged,
    required this.onSecondaryColorChanged,
  }) : super(key: key);

  @override
  State<ColorThemeDialog> createState() => _ColorThemeDialogState();
}

class _ColorThemeDialogState extends State<ColorThemeDialog> {
  late Color _primaryColor;
  late Color _secondaryColor;
  bool _editingPrimary = true;

  // Use Material Design colors, avoid pure brights
  final List<Color> materialColors = [
    Colors.blue.shade700,
    Colors.red.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
    Colors.pink.shade400,
    Colors.teal.shade700,
    Colors.indigo.shade700,
    Colors.deepOrange.shade600,
    Colors.amber.shade700,
    Colors.cyan.shade700,
    Colors.lime.shade700,
    Colors.brown.shade700,
    Colors.grey.shade800,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _primaryColor = widget.primaryColor;
    _secondaryColor = widget.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _editingPrimary
                            ? Colors.white24
                            : Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => setState(() => _editingPrimary = true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: _primaryColor,
                            radius: 10,
                          ),
                          const SizedBox(width: 8),
                          const Text('Primary'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: !_editingPrimary
                            ? Colors.white24
                            : Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => setState(() => _editingPrimary = false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: _secondaryColor,
                            radius: 10,
                          ),
                          const SizedBox(width: 8),
                          const Text('Secondary'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Material Color Swatches
              Text(
                "Material Colors",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: materialColors.map((c) {
                  bool selected =
                      (_editingPrimary ? _primaryColor : _secondaryColor) == c;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_editingPrimary) {
                          _primaryColor = c;
                          widget.onPrimaryColorChanged(_primaryColor);
                        } else {
                          _secondaryColor = c;
                          widget.onSecondaryColorChanged(_secondaryColor);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 16,
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // Advanced Color Picker
              Text(
                "Pick Any Color",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ColorPicker(
                pickerColor: _editingPrimary ? _primaryColor : _secondaryColor,
                onColorChanged: (color) {
                  setState(() {
                    if (_editingPrimary) {
                      _primaryColor = color;
                      widget.onPrimaryColorChanged(_primaryColor);
                    } else {
                      _secondaryColor = color;
                      widget.onSecondaryColorChanged(_secondaryColor);
                    }
                  });
                },
                enableAlpha: false,
                showLabel: false,
                pickerAreaHeightPercent: 0.7,
                displayThumbColor: true,
              ),
              const SizedBox(height: 18),
              // Dummy preview: secondary is background, primary is button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: useWhiteForeground(_primaryColor)
                          ? Colors.white
                          : Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Sample Button"),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
