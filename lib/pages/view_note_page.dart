import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../components/noteblock.dart';
import '../models/note.dart';
import '../models/note_database.dart';
import '../components/decimal_precision_provider.dart';
import '../components/calculation_channel.dart';

class _ChartSampleData {
  final double x, y;
  _ChartSampleData(this.x, this.y);
}

class ViewNotePage extends StatefulWidget {
  final Note note;

  const ViewNotePage({
    super.key,
    required this.note,
  });

  @override
  _ViewNotePageState createState() => _ViewNotePageState();
}

class _ViewNotePageState extends State<ViewNotePage> {
  late Note note;

  @override
  void initState() {
    super.initState();
    note = widget.note; // Initialize note from the widget
  }

  void deleteNote(int id) {
    context.read<NoteDatabase>().deleteNote(id);
  }

  void _confirmDeleteNote() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Note',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this note?',
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
                deleteNote(note.id);
                Navigator.of(context).pop(); // Close the alert
                Navigator.of(context).pop(); // Close the ViewNotePage
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

  // Helper method to view graph
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

  // Helper that evaluates “expr at a single xVal”
  Future<_ChartSampleData> _evaluateAtX(
      String eqText, double xVal, BuildContext ctx) async {
    String expr = eqText;
    if (expr.startsWith('y=')) {
      expr = expr.substring(2);
    }
    // Replace all “x” tokens with numeric
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 25),
            child: IconButton(
              onPressed: _confirmDeleteNote,
              icon: Icon(
                Icons.delete_outlined,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note title outside scrollable section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              child: Text(
                note.header,
                style: GoogleFonts.dmSerifText(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...note.blocks.map((block) {
                        if (block is TextBlock) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              block.content,
                              style: TextStyle(
                                fontSize: 17,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                          );
                        } else if (block is GraphBlock) {
                          // readonly graph block
                          final zoomPan = ZoomPanBehavior(
                            enablePinching: true,
                            enablePanning: true,
                          );
                          Widget chartArea;

                          if (block.equations.isEmpty || block.equations.last.trim().isEmpty) {
                            chartArea = Container(
                              height: 200,
                              alignment: Alignment.center,
                              child: Text(
                                'No graph plotted',
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
                                      interval: (block.maxX - block.minX) / 5,
                                    ),
                                    primaryYAxis: NumericAxis(
                                      minimum: block.minY.toDouble(),
                                      maximum: block.maxY.toDouble(),
                                      interval: (block.maxY - block.minY) / 5,
                                    ),
                                    series: <LineSeries<_ChartSampleData, double>>[
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
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  // the chart
                                  chartArea,

                                  // show the equation(s) underneath
                                  if (block.equations.isNotEmpty && block.equations.last.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      child: Text(
                                        block.equations.last,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Theme.of(context).colorScheme.inversePrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }).toList(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
