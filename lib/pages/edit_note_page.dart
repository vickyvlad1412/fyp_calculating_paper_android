import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:calculating_paper/models/note.dart';
import 'package:calculating_paper/models/note_database.dart';
import '../components/calculation_channel.dart';
import '../components/custom_keyboard_container.dart';
import '../components/decimal_precision_provider.dart';
import '../components/noteblock.dart';
import '../components/variable_manager.dart';
import 'dart:async';
import 'home_page.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class _ChartSampleData {
  final double x, y;
  _ChartSampleData(this.x, this.y);
}


class EditNotePage extends StatefulWidget {
  final Note note;

  const EditNotePage({super.key, required this.note});

  @override
  EditNotePageState createState() => EditNotePageState();
}

class EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  TextEditingController? _activeController;
  BuildContext? _activeTextFieldContext;
  late FocusNode _contentFocusNode;
  bool _isCustomKeyboardVisible = false;
  final VariableManager variableManager = VariableManager();
  Timer? _debounce;
  List<NoteBlock> blocks = [TextBlock(initialContent: '')];
  final ScrollController _scrollController = ScrollController();

  GraphBlock? _blockForController(TextEditingController ctrl) {
    for (final block in blocks) {
      if (block is GraphBlock && block.controller == ctrl) {
        return block;
      }
    }
    return null;
  }



  @override
  void initState() {
    super.initState();
    _contentFocusNode = FocusNode();
    _titleController = TextEditingController(text: widget.note.header);

    // Deserialize saved blocks
    try {
      blocks = widget.note.blocks;
    } catch (e) {
      // Fallback to a single empty text block if something goes wrong
      blocks = [TextBlock(initialContent: '')];
    }

    // Initialize autosave for each TextBlock's controller
    for (final block in blocks) {
      if (block is TextBlock) {
        block.controller.addListener(_triggerAutosave);
      } else if (block is GraphBlock) {
        block.controller.addListener(_triggerAutosave);
      }
    }

    // Track title changes
    _titleController.addListener(_triggerAutosave);

    // Automatically show the custom keyboard after the page is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {

        Future.delayed(const Duration(milliseconds: 100), () {
          _contentFocusNode.requestFocus(); // Request focus to show default keyboard
        });
        // Immediately hide the default keyboard
        SystemChannels.textInput.invokeMethod('TextInput.hide');

        // Keep the focus on the text field
        _contentFocusNode.requestFocus();

        // Delay to ensure a smooth transition before showing the custom keyboard
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            _isCustomKeyboardVisible = true; // Show custom keyboard
          });
        });
      });
    });
  }

  @override
  void dispose() {
    // Dispose all block controllers
    for (final block in blocks) {
      if (block is TextBlock) {
        block.controller.removeListener(_triggerAutosave);
        block.controller.dispose();
      } else if (block is GraphBlock) {
        block.controller.removeListener(_triggerAutosave);
        block.controller.dispose();
      }
    }

    _titleController.removeListener(_triggerAutosave);
    _titleController.dispose();
    _contentFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _triggerAutosave() {
    // Cancel the previous timer if still running
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Set up a new timer to call saveNote after a delay
    _debounce = Timer(const Duration(milliseconds: 100), saveNote);
  }

  void saveNote() {
    final newHeader = _titleController.text.trim();
    widget.note.header = newHeader;
    widget.note.blocks = blocks;

    context.read<NoteDatabase>().updateNote(widget.note.id, widget.note.header, widget.note.serializedBlocks,);
  }

  void toggleKeyboard() {
    setState(() {
      if (_isCustomKeyboardVisible) {
        // Switching to the default keyboard
        _isCustomKeyboardVisible = false;

        // Delay to allow the custom keyboard to slide out before showing the default
        Future.delayed(const Duration(milliseconds: 100), () {
          _contentFocusNode.requestFocus(); // Request focus to show default keyboard
        });
      } else {
        // Switching to the custom keyboard
        // Immediately hide the default keyboard
        SystemChannels.textInput.invokeMethod('TextInput.hide');

        // Keep the focus on the text field to prevent losing it
        _contentFocusNode.requestFocus();

        // Delay to ensure a smooth transition before showing the custom keyboard
        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            _isCustomKeyboardVisible = true; // Show custom keyboard
          });
        });
      }
    });
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Calculation Error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrecisionDialog(BuildContext context) {
    final provider = Provider.of<DecimalPrecisionProvider>(context, listen: false);
    final controller = TextEditingController(text: provider.decimalPrecision.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Decimal Precision',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
          decoration: InputDecoration(
            hintText: 'Enter precision',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final entered = int.tryParse(controller.text);
              if (entered != null) {
                provider.updatePrecision(entered);
              }
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBlock(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Remove Block',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to remove this block?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  blocks.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void handleKeyPress(String key, Note note) async {
    if (_activeController == null) return;
    final ctrl = _activeController!;
    final rawText = ctrl.text;
    final selection = ctrl.selection;
    final cursorPosition = selection.start;

    // Determine which block this controller belongs to:
    TextBlock? textBlock;
    GraphBlock? graphBlock;
    for (final block in blocks) {
      if (block is TextBlock && block.controller == ctrl) {
        textBlock = block;
        break;
      }
      if (block is GraphBlock && block.controller == ctrl) {
        graphBlock = block;
        break;
      }
    }

    // Split into lines so we can identify the “current line”:
    final lines = rawText.split('\n');
    int lineIndex = 0;
    int charCount = 0;
    for (int i = 0; i < lines.length; i++) {
      charCount += lines[i].length + 1; // +1 for the “\n”
      if (cursorPosition <= charCount) {
        lineIndex = i;
        break;
      }
    }
    final currentLine = lines[lineIndex];

    if (textBlock != null) {
      const functions = [
        "sin", "cos", "tan", "arcsin", "arccos", "arctan",
        "sinh", "cosh", "tanh", "log", "ln", "√", "exp"
      ];

      if (functions.contains(key)) {
        // Check if currentLine (ignoring any leading “=”) is exactly a single number
        // possibly in scientific (“E”) form:
        final trimmed = currentLine.trim();
        final withoutEqual =
        trimmed.startsWith('=') ? trimmed.substring(1).trim() : trimmed;
        // Regex matches: optional sign, digits, optional decimal, optional “E±exponent”
        final singleNumberRegex = RegExp(r'^[+-]?\d+(\.\d+)?([eE][+-]?\d+)?$');
        final isSingleNum = singleNumberRegex.hasMatch(withoutEqual);

        if (isSingleNum) {
          final leadingEqual = trimmed.startsWith('=') ? '=' : '';
          final replacementInside = "$key($withoutEqual)";
          // Build new line fresh:
          final newLine = leadingEqual + replacementInside;
          // Compute the start index of this line in rawText:
          int startOfLine = charCount - lines[lineIndex].length - 1;
          int endOfLine = startOfLine + lines[lineIndex].length;

          final newText = rawText.replaceRange(
            startOfLine,
            endOfLine,
            newLine,
          );
          ctrl.text = newText;

          // Place cursor right after the closing “)” of the function
          final newCursor = startOfLine + newLine.length;
          ctrl.selection = TextSelection.collapsed(offset: newCursor);
        } else {
          // Not a single number: fall back to “insert key()” at the cursor
          final insertion = "$key()";
          final newText = rawText.replaceRange(
            selection.start,
            selection.end,
            insertion,
          );
          ctrl.text = newText;
          final newCursor = cursorPosition + key.length + 1; // between ()
          ctrl.selection = TextSelection.collapsed(offset: newCursor);
        }
        return;
      }

      // Parentheses button "(  )" – just insert "(  )" at cursor:
      if (key == "(  )") {
        final insertion = "(  )";
        final newText = rawText.replaceRange(
          selection.start,
          selection.end,
          insertion,
        );
        ctrl.text = newText;
        ctrl.selection = TextSelection.collapsed(offset: cursorPosition + 2);
        return;
      }

      // Any other normal key (digit, +, –, etc.) – insert at cursor as usual:
      final newText = rawText.replaceRange(
        selection.start,
        selection.end,
        key,
      );
      final newCursorPosition = selection.start + key.length;
      ctrl.text = newText;
      ctrl.selection = TextSelection.collapsed(offset: newCursorPosition);
      return;
    }

    // If this is a GraphBlock, run the graph logic
    if (graphBlock != null) {
      const functions = [
        "sin", "cos", "tan", "arcsin", "arccos", "arctan",
        "sinh", "cosh", "tanh", "log", "ln", "√", "exp"
      ];

      if (functions.contains(key)) {
        final replacement = "$key()";
        final newText = rawText.replaceRange(
          selection.start,
          selection.end,
          replacement,
        );
        ctrl.text = newText;
        ctrl.selection = TextSelection.collapsed(
          offset: cursorPosition + key.length + 1,
        );
      } else if (key == "(  )") {
        final replacement = "(  )";
        final newText = rawText.replaceRange(
          selection.start,
          selection.end,
          replacement,
        );
        ctrl.text = newText;
        ctrl.selection = TextSelection.collapsed(offset: cursorPosition + 2);
      } else {
        final newText = rawText.replaceRange(
          selection.start,
          selection.end,
          key,
        );
        final newCursorPosition = selection.start + key.length;
        ctrl.text = newText;
        ctrl.selection = TextSelection.collapsed(offset: newCursorPosition);
      }

      // Now that graph‐text changed, update block.equations
      if (graphBlock.equations.isEmpty) {
        graphBlock.equations.add(ctrl.text);
      } else {
        graphBlock.equations[graphBlock.equations.length - 1] = ctrl.text;
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Decimal Precision',
            onPressed: () => _showPrecisionDialog(context),
            icon: Icon(
              Icons.tune_outlined,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          IconButton(
            onPressed: saveNote,
            icon: Icon(
              Icons.save_outlined,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: Theme.of(context).colorScheme.inversePrimary,
                      selectionColor: Theme.of(context).colorScheme.secondary,
                      selectionHandleColor: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  child: TextField(
                    controller: _titleController,
                    keyboardType: _isCustomKeyboardVisible ? TextInputType.none : TextInputType.multiline,
                    cursorColor: Theme.of(context).colorScheme.inversePrimary,
                    style: GoogleFonts.dmSerifText(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Title",
                      hintStyle: GoogleFonts.dmSerifText(
                        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8),
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: blocks.length,
                    itemBuilder: (context, index) {
                      final block = blocks[index];
                      if (block is TextBlock) {
                        final controller = block.controller;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Stack(
                            children: [
                              Focus (
                                onFocusChange: (hasFocus) {
                                  if (hasFocus) {
                                    _activeController = controller;
                                    _activeTextFieldContext = context;

                                    // Ensure the text field scrolls into view
                                    Future.delayed(Duration(milliseconds: 100), () {
                                      if (block.key.currentContext != null) {
                                        Scrollable.ensureVisible(
                                          block.key.currentContext!,
                                          duration: Duration(milliseconds: 200),
                                          alignment: 0.5, // Center it vertically in view
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    });
                                  }
                                },
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    textSelectionTheme: TextSelectionThemeData(
                                      cursorColor: Theme.of(context).colorScheme.inversePrimary,
                                      selectionColor: Theme.of(context).colorScheme.secondary,
                                      selectionHandleColor: Theme.of(context).colorScheme.inversePrimary,
                                    ),
                                  ),
                                  child: Container(
                                    key: block.key,
                                    child: TextField(
                                      controller: block.controller,
                                      keyboardType: _isCustomKeyboardVisible ? TextInputType.none : TextInputType.multiline,
                                      readOnly: _isCustomKeyboardVisible,
                                      maxLines: null,
                                      onChanged: (value) => block.content = value,
                                      showCursor: true,
                                      cursorColor: Theme.of(context).colorScheme.inversePrimary,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Theme.of(context).colorScheme.inversePrimary,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Your calculation here",
                                        hintStyle: TextStyle(
                                          color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8),
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Delete button to delete the block
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                  onPressed: () => _confirmDeleteBlock(index),
                                  tooltip: 'Remove Block',
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (block is GraphBlock) {
                        final eqController = block.controller;
                        final zoomPan = ZoomPanBehavior(enablePinching: true, enablePanning: true);
                        Widget chartArea;
                        if (block.equations.isEmpty) {
                          chartArea = Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: Text(
                              'No graph plotted yet',
                              style: TextStyle(color: Theme.of(context).hintColor),
                            ),
                          );
                        } else {
                          chartArea = FutureBuilder<List<_ChartSampleData>>(
                            future: _generateChartData(block, context),
                            builder: (ctx, snapshot) {
                              final data = (snapshot.data ?? [])
                                  .where((pt) => pt.y.isFinite)
                                  .toList();
                              return SizedBox(
                                height: 200,
                                child: SfCartesianChart(
                                  zoomPanBehavior: zoomPan,
                                  primaryXAxis: NumericAxis(
                                    minimum: block.minX.toDouble(),
                                    maximum: block.maxX.toDouble(),
                                    interval: (block.maxX - block.minX)/5,
                                  ),
                                  primaryYAxis: NumericAxis(
                                    minimum: block.minY.toDouble(),
                                    maximum: block.maxY.toDouble(),
                                    interval: (block.maxY - block.minY)/5,
                                  ),
                                  series: [
                                    LineSeries<_ChartSampleData, double>(
                                      dataSource: data,
                                      xValueMapper: (pt, _) => pt.x,
                                      yValueMapper: (pt, _) => pt.y,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Stack(
                            children: [
                              Container(
                                key: block.key,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 30),
                                    chartArea,
                                    const SizedBox(height: 8),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        children: [
                                          // equation TextField, no border
                                          Expanded(
                                            child: Focus(
                                              onFocusChange: (hasFocus) {
                                                if (hasFocus) {
                                                  // Tell custom-keyboard logic which controller to edit
                                                  _activeController = eqController;
                                                  _activeTextFieldContext = context;
                                                  // Hide system keyboard immediately
                                                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                                                  // Ensure cursor goes to end
                                                  final len = eqController.text.length;
                                                  eqController.selection = TextSelection.collapsed(offset: len);
                                                }
                                              },
                                              child: TextField(
                                                controller: eqController,
                                                keyboardType: _isCustomKeyboardVisible
                                                    ? TextInputType.none
                                                    : TextInputType.multiline,
                                                readOnly: _isCustomKeyboardVisible,
                                                maxLines: 1,
                                                showCursor: true,
                                                cursorColor: Theme.of(context).colorScheme.inversePrimary,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  color: Theme.of(context).colorScheme.inversePrimary,
                                                ),
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    borderSide: BorderSide(
                                                      color: Theme.of(context).colorScheme.inversePrimary,
                                                    ),
                                                  ),
                                                  hintText: 'y = …',
                                                  hintStyle: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary
                                                        .withOpacity(0.6),
                                                    fontSize: 17,
                                                  ),
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Plot button
                                          ElevatedButton(
                                            onPressed: () {
                                              final eq = eqController.text.trim();
                                              if (eq.isEmpty) {
                                                _showErrorDialog(context, 'Please enter an equation to plot.');
                                                return;
                                              }
                                              setState(() {
                                                block.equations = [eq];
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.secondary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Plot',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.inversePrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                              // Delete Button for block
                              Positioned (
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_outlined,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.inversePrimary,
                                  ),
                                  onPressed: () => _confirmDeleteBlock(index),
                                  tooltip: 'Remove Block',
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: toggleKeyboard,
                icon: Icon(
                  _isCustomKeyboardVisible ? Icons.keyboard_outlined : Icons.calculate_outlined,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              if (_isCustomKeyboardVisible)
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 100),
                  switchInCurve: Curves.easeIn,
                  child: CustomKeyboardContainer(
                    onKeyPress: (key) {
                      handleKeyPress(key, widget.note);
                    },
                    onBackspacePress: () {
                      if(_activeController == null) return;

                      final text = _activeController!.text;
                      final selection = _activeController!.selection;

                      if (selection.start == 0 && selection.end == 0) {
                        // If the cursor is at the start of the text, do nothing
                        return;
                      }

                      if (selection.start == selection.end) {
                        // No selection, remove the character before the cursor
                        final newStart = selection.start - 1;
                        final newText = text.replaceRange(newStart, selection.start, '');
                        _activeController!.text = newText;
                        _activeController!.selection = TextSelection.collapsed(offset: newStart);
                      } else {
                        // There is a selection, remove the selected text
                        final newText = text.replaceRange(selection.start, selection.end, '');
                        _activeController!.text = newText;
                        _activeController!.selection = TextSelection.collapsed(offset: selection.start);
                      }
                    },
                    onEnterPress: () {
                      if(_activeController == null || _activeTextFieldContext == null) return;

                      final text = _activeController!.text;
                      final selection = _activeController!.selection;

                      final cursorPosition = selection.start;
                      final newText = '${text.substring(0, cursorPosition)}\n${text.substring(cursorPosition)}';

                      // Update the text in the controller
                      _activeController!.text = newText;

                      // Move the cursor to the start of the new line (after the inserted newline)
                      final newCursorPosition = cursorPosition + 1;
                      _activeController!.selection = TextSelection.collapsed(offset: newCursorPosition);

                      Future.delayed(Duration(milliseconds: 100), () {
                        SystemChannels.textInput.invokeMethod('TextInput.hide'); // Keep default keyboard hidden

                        // Find the active block that owns the controller
                        try {
                          final block = blocks.firstWhere(
                                (b) => b is TextBlock && b.controller == _activeController,
                          ) as TextBlock;

                          if(block is TextBlock && block.key.currentContext != null) {
                            Scrollable.ensureVisible(
                              block.key.currentContext!,
                              duration: Duration(milliseconds: 200),
                              alignment: 0.5,
                              curve: Curves.easeInOut,
                            );
                          }
                        } catch (e){
                          // Ignore
                        }
                      });
                    },
                  ),
                ),
            ],
          ),
          // Floating Evaluate button and Graph button
          Positioned(
            bottom: _isCustomKeyboardVisible ? 300 : 20, // Adjust position based on keyboard visibility
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'graph_btn',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      blocks.add(GraphBlock(initialEquations: []));
                      blocks.add(TextBlock(initialContent: ''));
                    });
                  },
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.show_chart_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () async {
                    await evaluateExpression(widget.note);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                    minimumSize: const Size(100, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Evaluate',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for graphing feature
  Future<List<_ChartSampleData>> _generateChartData(
      GraphBlock block, BuildContext context) async {
    final eqText = (block.equations.isEmpty ? '' : block.equations.last).trim();
    final int steps = 100; // Number of sample points
    final double stepSize = (block.maxX - block.minX) / steps;

    List<Future<_ChartSampleData>> futures = [];

    for (int i = 0; i <= steps; i++) {
      final double xVal = block.minX + stepSize * i;
      futures.add(_evaluateAtX(eqText, xVal, context));
    }

    final results = await Future.wait(futures);
    // Compute minY/maxY
    double minY = double.infinity;
    double maxY = -double.infinity;
    for (var pt in results) {
      if (pt.y.isFinite) {
        if (pt.y < minY) minY = pt.y;
        if (pt.y > maxY) maxY = pt.y;
      }
    }
    // Fall back to –10…10 if all y are invalid
    if (minY == double.infinity || maxY == -double.infinity) {
      minY = -10;
      maxY = 10;
    } else if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    // Convert with floor/ceil so sin/cos get the right range
    final int lower = minY.floor();
    final int upper = maxY.ceil();

    // If it is still flat, expand by 1 on each side
    block.minY = (lower == upper) ? lower - 1: lower;
    block.maxY = (lower == upper) ? upper + 1 : upper;

    return results;
  }

  // Helper that evaluates “expr at a single xVal”:
  Future<_ChartSampleData> _evaluateAtX(
      String eqText, double xVal, BuildContext ctx) async {
    String expr = eqText;
    if (expr.startsWith('y=')) {
      expr = expr.substring(2);
    }
    // Replace all “x” tokens with numeric:
    expr = expr.replaceAllMapped(RegExp(r'\bx\b'), (_) => xVal.toString());

    try {
      final precision =
          Provider.of<DecimalPrecisionProvider>(ctx, listen: false)
              .decimalPrecision;
      final resultStr =
      await CalculationChannel.evaluateExpression(expr, precision);
      final yVal = double.tryParse(resultStr) ?? double.nan;
      return _ChartSampleData(xVal, yVal);
    } catch (e) {
      return _ChartSampleData(xVal, double.nan);
    }
  }

  // Method for handling "Evaluate" button press
  Future<void> evaluateExpression(Note note) async {
    // Find which controller & block are active
    if (_activeController == null) return;
    final ctrl = _activeController!;
    final rawText = ctrl.text;
    final selection = ctrl.selection;
    final cursorPosition = selection.start;

    // Split into lines and find the current line index
    final lines = rawText.split('\n');
    int lineIndex = 0;
    int charCount = 0;
    for (int i = 0; i < lines.length; i++) {
      charCount += lines[i].length + 1;
      if (cursorPosition <= charCount) {
        lineIndex = i;
        break;
      }
    }
    final currentLine = lines[lineIndex];
    final decimalPrecision =
        Provider.of<DecimalPrecisionProvider>(context, listen: false)
            .decimalPrecision;

    // Is it a variable assignment line (“x = …”)
    final variableAssignment = RegExp(r'^(\w+)\s*=\s*(.+)$');
    final match = variableAssignment.firstMatch(currentLine);

    if (match != null) {
      // It’s “var = expr”.  Evaluate “expr”
      final variable = match.group(1)!.trim();
      final expression = match.group(2)!.trim();
      try {
        final result =
        await CalculationChannel.evaluateExpression(expression, decimalPrecision);

        // Store variable in VariableManager
        setState(() {
          variableManager
              .setVariable(note.id, variable, Decimal.parse(result.toString()));
        });

        // Replace that entire line (lineIndex) with “var = result”
        lines[lineIndex] = '$variable = $result';

        // Re-join all lines back into text, but do not add a blank line below
        final newTextBlock = lines.join('\n');
        ctrl.text = newTextBlock;

        // Move cursor to the very end of the “= result” line
        int lastLineLength = lines[lineIndex].length;
        // Compute index of the start of this line in newTextBlock
        int startOfLine = 0;
        for (int i = 0; i < lineIndex; i++) {
          startOfLine += lines[i].length + 1; // +1 for '\n'
        }
        final newCursorPos = startOfLine + lastLineLength;
        ctrl.selection = TextSelection.collapsed(offset: newCursorPos);
      } catch (e) {
        _showErrorDialog(context, e.toString());
        return;
      }
    }
    else {
      // Just a normal expression, no “var =”.  Evaluate the whole line
      // First replace any user‐defined variables
      String processedExpression = currentLine;
      final variablesMap = variableManager.getVariables(note.id) ?? {};
      variablesMap.forEach((key, value) {
        processedExpression =
            processedExpression.replaceAllMapped(RegExp(r'\b' + key + r'\b'),
                    (match) {
                  return value.toString();
                });
      });

      try {
        final result =
        await CalculationChannel.evaluateExpression(processedExpression, decimalPrecision);

        // (original lines[0..lineIndex]) + (the new “= $result” appended on its own line),
        // but no additional blank line after that
        final newLine = '= $result';
        final beforeLines = lines.sublist(0, lineIndex + 1);
        final afterLines = lines.length > (lineIndex + 1)
            ? lines.sublist(lineIndex + 1)
            : <String>[];

        // Reassemble: everything up to and including current line,
        // then the “= result” line, then whatever lines were below.
        final newLines = <String>[
          ...beforeLines,
          newLine,
          ...afterLines,
        ];
        final newTextBlock = newLines.join('\n');
        ctrl.text = newTextBlock;

        // Place cursor at end of the “= result” line
        int startOfResultLine = 0;
        for (int i = 0; i <= lineIndex; i++) {
          startOfResultLine += lines[i].length + 1;
        }
        // Now that “= result” is at newLines[lineIndex + 1], its length is newLine.length
        final newCursorPos = startOfResultLine + newLine.length;
        ctrl.selection = TextSelection.collapsed(offset: newCursorPos);
      } catch (e) {
        _showErrorDialog(context, e.toString());
        return;
      }
    }

    // Autoscroll so that “= result” is visible
    Future.delayed(Duration(milliseconds: 100), () {
      SystemChannels.textInput.invokeMethod('TextInput.hide'); // Keep default keyboard hidden

      // Find the active block that owns the controller
      try {
        final block = blocks.firstWhere(
              (b) => b is TextBlock && b.controller == _activeController,
        ) as TextBlock;

        if(block is TextBlock && block.key.currentContext != null) {
          Scrollable.ensureVisible(
            block.key.currentContext!,
            duration: Duration(milliseconds: 200),
            alignment: 0.5,
            curve: Curves.easeInOut,
          );
        }
      } catch (e){
        // Ignore
      }
    });
  }
}
