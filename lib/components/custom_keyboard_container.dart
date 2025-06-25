import 'dart:async';
import 'package:flutter/material.dart';
import 'custom_keyboard.dart';

class CustomKeyboardContainer extends StatefulWidget {
  final Function(String) onKeyPress;
  final Function() onEnterPress;
  final Function() onBackspacePress;

  const CustomKeyboardContainer({
    super.key,
    required this.onKeyPress,
    required this.onEnterPress,
    required this.onBackspacePress,
  });

  @override
  State<CustomKeyboardContainer> createState() => _CustomKeyboardContainerState();
}

class _CustomKeyboardContainerState extends State<CustomKeyboardContainer> {
  int _currentPage = 1;

  void _updatePage(int pageIndex) {
    setState(() {
      _currentPage = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    Timer? _backspaceTimer;

    return Container(
      height: 250, // Fixed keyboard height
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                // Page Navigation Buttons
                _buildToolbarButton("abc", 0),
                _buildToolbarButton("+/-", 1),
                _buildToolbarButton("f(x)", 2),
                const Spacer(),
                // Enter Icon
                IconButton(
                  onPressed: widget.onEnterPress, // Trigger Enter
                  icon: const Icon(Icons.subdirectory_arrow_left_outlined, size: 24),
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                // Backspace Icon
                GestureDetector(
                  onTap: widget.onBackspacePress, // Trigger Backspace on tap
                  onLongPressStart: (_) {
                    // Start deleting on long press
                    _backspaceTimer = Timer.periodic(
                      Duration(milliseconds: 100),
                        (timer) {
                          widget.onBackspacePress();
                        },
                    );
                  },
                  onLongPressEnd: (_) {
                    // Stop deleting when long press ends
                    _backspaceTimer?.cancel();
                  },
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),
          // Keyboard Content
          Expanded(
            child: CustomKeyboard(
              currentPage: _currentPage,
              onKeyPress: widget.onKeyPress,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, int pageIndex) {
    final isSelected = _currentPage == pageIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => _updatePage(pageIndex),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.inversePrimary
                : Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}





