import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics_snapshot.dart';
import '../models/session_log.dart';

/// Energy flow chart with session overlays
class EnergyFlowChart extends StatelessWidget {
  const EnergyFlowChart({
    super.key,
    required this.energyData,
    this.sessions = const [],
    this.showPrediction = false,
    this.predictedData = const [],
  });

  final List<EnergyDataPoint> energyData;
  final List<SessionLog> sessions;
  final bool showPrediction;
  final List<EnergyDataPoint> predictedData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (energyData.isEmpty) {
      return Center(
        child: Text(
          'No energy data yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          _buildChartData(theme),
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }

  LineChartData _buildChartData(ThemeData theme) {
    // Group energy data by hour
    final hourlyData = <int, List<int>>{};
    for (final point in energyData) {
      final hour = point.hourOfDay;
      hourlyData.putIfAbsent(hour, () => []).add(point.energy);
    }

    // Calculate averages
    final averages = hourlyData.map((hour, energies) {
      final avg = energies.reduce((a, b) => a + b) / energies.length;
      return MapEntry(hour, avg);
    });

    // Create spots for line chart
    final spots = averages.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList()..sort((a, b) => a.x.compareTo(b.x));

    // Prediction spots
    final predictionSpots = <FlSpot>[];
    if (showPrediction && predictedData.isNotEmpty) {
      final predictionHourly = <int, List<int>>{};
      for (final point in predictedData) {
        final hour = point.hourOfDay;
        predictionHourly.putIfAbsent(hour, () => []).add(point.energy);
      }

      predictionSpots.addAll(
        predictionHourly.entries.map((entry) {
          final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
          return FlSpot(entry.key.toDouble(), avg);
        }).toList()..sort((a, b) => a.x.compareTo(b.x)),
      );
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outline.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 3,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final hour = value.toInt();
              if (hour < 0 || hour > 23) return const SizedBox.shrink();
              return Text(
                '${hour}h',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        // Main energy line
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.4,
          color: theme.colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: theme.colorScheme.primary,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withOpacity(0.3),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
            ),
          ),
        ),

        // Prediction line
        if (showPrediction && predictionSpots.isNotEmpty)
          LineChartBarData(
            spots: predictionSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: theme.colorScheme.secondary.withOpacity(0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final hour = spot.x.toInt();
              final energy = spot.y.toInt();
              return LineTooltipItem(
                '${hour}:00\n$energy energy',
                theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

/// Productivity velocity chart (tasks per week)
class VelocityChart extends StatelessWidget {
  const VelocityChart({
    super.key,
    required this.weeklyData,
  });

  final Map<int, int> weeklyData; // week number -> task count

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (weeklyData.isEmpty) {
      return Center(
        child: Text(
          'No velocity data yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final spots = weeklyData.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList()..sort((a, b) => a.x.compareTo(b.x));

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      'W${value.toInt()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: theme.colorScheme.secondary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: theme.colorScheme.secondary,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.secondary.withOpacity(0.3),
                      theme.colorScheme.secondary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focus quality radar chart
class FocusQualityRadar extends StatelessWidget {
  const FocusQualityRadar({
    super.key,
    required this.metrics,
  });

  final Map<String, double> metrics; // metric name -> score (0-100)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (metrics.isEmpty) {
      return Center(
        child: Text(
          'No quality metrics yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 5,
            ticksTextStyle: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            radarBorderData: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 2,
            ),
            gridBorderData: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            tickBorderData: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
            getTitle: (index, angle) {
              final entries = metrics.entries.toList();
              if (index >= entries.length) return const RadarChartTitle(text: '');

              return RadarChartTitle(
                text: entries[index].key,
                angle: angle,
              );
            },
            dataSets: [
              RadarDataSet(
                fillColor: theme.colorScheme.primary.withOpacity(0.3),
                borderColor: theme.colorScheme.primary,
                borderWidth: 2,
                dataEntries: metrics.values.map((value) {
                  return RadarEntry(value: value);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
