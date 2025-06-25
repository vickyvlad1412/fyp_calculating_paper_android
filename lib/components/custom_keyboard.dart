import 'package:flutter/material.dart';

class CustomKeyboard extends StatelessWidget {
  final int currentPage;
  final Function(String) onKeyPress;

  const CustomKeyboard({
    super.key,
    required this.currentPage,
    required this.onKeyPress,
  });

  List<List<String>> get _pages => [
    // Page 1: 8x4 grid (Alphabets & Greek Letters)
    [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
      'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
      'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
      'y', 'z', 'α', 'β', 'γ', 'δ', 'θ', 'φ',
    ],
    // Page 2: 4x5 grid (Numbers & Operators)
    [
      '7', '8', '9', '÷', '^',
      '4', '5', '6', '*', '(  )',
      '1', '2', '3', '-', 'e',
      '0', '.', '=', '+', 'π',
    ],
    // Page 3: 4x4 grid (Functions)
    [
      'sin', 'cos', 'tan', 'log',
      'arcsin', 'arccos', 'arctan', 'ln',
      'sinh', 'cosh', 'tanh', '^2',
      'exp', '!', '√', '^3',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final keys = _pages[currentPage];
    final columns = _getColumnsForPage(currentPage);
    final rows = _getRowsForPage(currentPage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final totalWidth = constraints.maxWidth;

        // Calculate button dimensions
        final spacing = 4.0; // Space between buttons
        final buttonWidth = (totalWidth - (columns - 1) * spacing) / columns;
        final buttonHeight =
            (totalHeight - (rows - 1) * spacing - 8.0) / rows; // Adjusted for padding

        // Divide keys into rows
        final keyRows = List.generate(
          rows,
              (rowIndex) => keys.sublist(
            rowIndex * columns,
            (rowIndex + 1) * columns,
          ),
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: keyRows.asMap().entries.map((entry) {
            final isLastRow = entry.key == rows - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLastRow ? 8.0 : 0.0), // Add padding to the last row
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: entry.value.map((label) {
                  return SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () => onKeyPress(label),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: FittedBox(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Get fixed column count for each page
  int _getColumnsForPage(int pageIndex) {
    switch (pageIndex) {
      case 0: // Page 1: Alphabets
        return 8;
      case 1: // Page 2: Numbers & Operators
        return 5;
      case 2: // Page 3: Functions
        return 4;
      default:
        return 8;
    }
  }

  // Get fixed row count for each page
  int _getRowsForPage(int pageIndex) {
    switch (pageIndex) {
      case 0: // Page 1: Alphabets
        return 4;
      case 1: // Page 2: Numbers & Operators
        return 4;
      case 2: // Page 3: Functions
        return 4;
      default:
        return 4;
    }
  }
}











