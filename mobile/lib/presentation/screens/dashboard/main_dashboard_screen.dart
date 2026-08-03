import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/telemetry.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/MainDashboard.jsx`.
///
/// The web page keys all of its copy off a `roleConfig` map and renders the
/// same three-column layout for every role; on a phone the columns stack but
/// the cards, copy, colours and charts are the same.

class _ChartMetrics {
  const _ChartMetrics({
    required this.left,
    required this.right,
    required this.leftColor,
    required this.rightColor,
  });

  final String left;
  final String right;
  final Color leftColor;
  final Color rightColor;
}

class _MiniMetrics {
  const _MiniMetrics({
    required this.left,
    required this.right,
    required this.leftVal,
    required this.rightVal,
  });

  final String left;
  final String right;
  final String leftVal;
  final String rightVal;
}

class _Widgets {
  const _Widgets({
    required this.analyticsLabel,
    required this.analyticsColor,
    required this.emailTitle,
    required this.email,
    required this.emailGradient,
    required this.serverLabel,
    required this.serverStatus,
    required this.serverColor,
  });

  final String analyticsLabel;
  final Color analyticsColor;
  final String emailTitle;
  final String email;
  final List<Color> emailGradient;
  final String serverLabel;
  final String serverStatus;
  final Color serverColor;
}

class _RoleConfig {
  const _RoleConfig({
    required this.primaryHeader,
    required this.secondaryHeader,
    required this.chartMetrics,
    required this.miniMetrics,
    required this.widgets,
  });

  final String primaryHeader;
  final String secondaryHeader;
  final _ChartMetrics chartMetrics;
  final _MiniMetrics miniMetrics;
  final _Widgets widgets;
}

const Map<UserRole, _RoleConfig> _roleConfig = <UserRole, _RoleConfig>{
  UserRole.doctor: _RoleConfig(
    primaryHeader: 'Clinical Portfolio',
    secondaryHeader: 'Appointment Volume',
    chartMetrics: _ChartMetrics(
      left: 'Confirmed Consults',
      right: 'Pending Reviews',
      leftColor: AppColors.success,
      rightColor: AppColors.primary500,
    ),
    miniMetrics: _MiniMetrics(
      left: 'Patient Flow',
      right: 'EMR Sync',
      leftVal: 'Active',
      rightVal: 'Online',
    ),
    widgets: _Widgets(
      analyticsLabel: 'Patient Adherence Matrix',
      analyticsColor: AppColors.success,
      emailTitle: 'Urgent Support Line',
      email: 'clinic@pediatric-hub.com',
      emailGradient: <Color>[AppColors.teal, Color(0xFF047857)],
      serverLabel: 'Clinical Roster Status',
      serverStatus: 'Available',
      serverColor: AppColors.success,
    ),
  ),
  UserRole.parent: _RoleConfig(
    primaryHeader: 'Family Health Portfolio',
    secondaryHeader: 'Clinical Interactions',
    chartMetrics: _ChartMetrics(
      left: 'Visits Completed',
      right: 'Vaccines Due',
      leftColor: AppColors.primary600,
      rightColor: AppColors.warning,
    ),
    miniMetrics: _MiniMetrics(
      left: 'Growth Track',
      right: 'Vax Track',
      leftVal: 'On Curve',
      rightVal: 'Protected',
    ),
    widgets: _Widgets(
      analyticsLabel: 'Wellness Trajectory',
      analyticsColor: AppColors.primary600,
      emailTitle: 'Pediatrician Contact',
      email: 'dr.admin@pediatric-hub.com',
      emailGradient: <Color>[AppColors.primary500, AppColors.primary800],
      serverLabel: 'Health Record Integrity',
      serverStatus: 'Encrypted',
      serverColor: AppColors.primary600,
    ),
  ),
  UserRole.facility: _RoleConfig(
    primaryHeader: 'Facility Operations',
    secondaryHeader: 'Throughput Volume',
    chartMetrics: _ChartMetrics(
      left: 'Provider Activity',
      right: 'Patient Intake',
      leftColor: AppColors.primary600,
      rightColor: AppColors.primary700,
    ),
    miniMetrics: _MiniMetrics(
      left: 'Capacity',
      right: 'Utilization',
      leftVal: '68%',
      rightVal: 'Optimal',
    ),
    widgets: _Widgets(
      analyticsLabel: 'Resource Optimization',
      analyticsColor: AppColors.primary600,
      emailTitle: 'Network Administrator',
      email: 'sysadmin@pediatric-hub.com',
      emailGradient: <Color>[AppColors.primary600, AppColors.primary900],
      serverLabel: 'Server Cloud Health',
      serverStatus: 'Operational',
      serverColor: AppColors.primary600,
    ),
  ),
  UserRole.admin: _RoleConfig(
    primaryHeader: 'System Operations',
    secondaryHeader: 'System Event Volume',
    chartMetrics: _ChartMetrics(
      left: 'API Ingress',
      right: 'Web Exits',
      leftColor: AppColors.primary600,
      rightColor: AppColors.teal,
    ),
    miniMetrics: _MiniMetrics(
      left: 'CPU',
      right: 'MEM',
      leftVal: '2%',
      rightVal: '42 MB',
    ),
    widgets: _Widgets(
      analyticsLabel: 'Analytics Matrix',
      analyticsColor: AppColors.primary600,
      emailTitle: 'Connect Support Email',
      email: 'secure@pediatric-hub.com',
      emailGradient: <Color>[AppColors.primary600, AppColors.primary900],
      serverLabel: 'Server Health',
      serverStatus: 'Zero Downtime',
      serverColor: AppColors.teal,
    ),
  ),
};

class MainDashboardScreen extends ConsumerWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DashboardTelemetry> telemetry = ref.watch(
      dashboardTelemetryProvider,
    );
    final UserRole role = ref.watch(currentRoleProvider) ?? UserRole.admin;
    final _RoleConfig config =
        _roleConfig[role] ?? _roleConfig[UserRole.admin]!;
    final AppPalette palette = context.palette;

    return telemetry.when(
      loading: () => Center(
        child: Text(
          'Aggregating Live Telemetry Variables...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.6,
          ),
        ),
      ),
      error: (Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                error is ApiException
                    ? error.detailedMessage
                    : error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(dashboardTelemetryProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (DashboardTelemetry stats) {
        final int chartTotal = stats.charts.fold<int>(
          0,
          (int acc, TelemetryPoint p) => acc + p.sales + p.orders,
        );

        return RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardTelemetryProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: <Widget>[
              _MicroLabel(config.primaryHeader),
              const SizedBox(height: 16),

              _PrimaryStatCard(
                label: stats.title1,
                badge: 'LIVE',
                badgeColor: config.chartMetrics.leftColor,
                value: stats.count1,
                valueSize: 36,
                spark: stats.charts.map((TelemetryPoint p) => p.uv).toList(),
                color: config.chartMetrics.leftColor,
              ),
              const SizedBox(height: 16),

              _PrimaryStatCard(
                label: stats.title2,
                badge: 'OK',
                badgeColor: config.chartMetrics.rightColor,
                value: stats.count2,
                valueSize: 32,
                spark: stats.charts.map((TelemetryPoint p) => p.sales).toList(),
                color: config.chartMetrics.rightColor,
                secondarySpark: stats.charts
                    .map((TelemetryPoint p) => p.orders)
                    .toList(),
                secondaryColor: config.chartMetrics.leftColor,
              ),
              const SizedBox(height: 16),

              // IntrinsicHeight gives the pair a shared, finite height. A bare
              // CrossAxisAlignment.stretch here would ask for infinite height
              // inside the ListView and blank the whole page.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _MiniBarsCard(
                        title: stats.title3,
                        value: stats.count3,
                        color: config.chartMetrics.leftColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MiniSplitCard(
                        metrics: config.miniMetrics,
                        leftColor: config.chartMetrics.leftColor,
                        rightColor: config.chartMetrics.rightColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _MicroLabel(config.secondaryHeader),
              const SizedBox(height: 16),
              _AggregateTrendsCard(
                total: chartTotal,
                points: stats.charts,
                metrics: config.chartMetrics,
              ),
              const SizedBox(height: 24),

              _AnalyticsGaugeCard(
                label: config.widgets.analyticsLabel,
                color: config.widgets.analyticsColor,
              ),
              const SizedBox(height: 16),
              _EmailCard(
                title: config.widgets.emailTitle,
                email: config.widgets.email,
                gradient: config.widgets.emailGradient,
              ),
              const SizedBox(height: 16),
              _ServerHealthCard(
                label: config.widgets.serverLabel,
                status: config.widgets.serverStatus,
                color: config.widgets.serverColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The uppercase micro heading above each column on the web.
class _MicroLabel extends StatelessWidget {
  const _MicroLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.palette.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final AppPalette palette = context.palette;
  return BoxDecoration(
    color: palette.surface,
    borderRadius: AppRadius.mdAll,
    border: Border.all(color: palette.border),
    boxShadow: AppShadows.sm,
  );
}

/// Stat card with the big number and an area sparkline underneath.
class _PrimaryStatCard extends StatelessWidget {
  const _PrimaryStatCard({
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.value,
    required this.valueSize,
    required this.spark,
    required this.color,
    this.secondarySpark,
    this.secondaryColor,
  });

  final String label;
  final String badge;
  final Color badgeColor;
  final int value;
  final double valueSize;
  final List<int> spark;
  final Color color;
  final List<int>? secondarySpark;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                badge,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$value',
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 58,
            child: _AreaSpark(
              series: <List<int>>[
                spark,
                if (secondarySpark != null) secondarySpark ?? <int>[],
              ],
              colors: <Color>[color, secondaryColor ?? color],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled area sparkline — the mobile stand-in for Recharts `<Area>`.
class _AreaSpark extends StatelessWidget {
  const _AreaSpark({required this.series, required this.colors});

  final List<List<int>> series;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final List<List<int>> valid = series
        .where((List<int> s) => s.isNotEmpty)
        .toList();
    if (valid.isEmpty) return const SizedBox.shrink();

    double maxY = 1;
    for (final List<int> s in valid) {
      for (final int v in s) {
        if (v.toDouble() > maxY) maxY = v.toDouble();
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.25,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: <LineChartBarData>[
          for (int i = 0; i < valid.length; i++)
            LineChartBarData(
              spots: <FlSpot>[
                for (int x = 0; x < valid[i].length; x++)
                  FlSpot(x.toDouble(), valid[i][x].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.3,
              color: colors[i % colors.length],
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    colors[i % colors.length].withValues(alpha: 0.55),
                    colors[i % colors.length].withValues(alpha: 0),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "title3" card with the 24 thin bars from the web.
class _MiniBarsCard extends StatelessWidget {
  const _MiniBarsCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final math.Random rng = math.Random(value + title.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: _cardDecoration(context),
      child: Column(
        children: <Widget>[
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(20, (int i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 3,
                    height: math.max(8, rng.nextDouble() * 34),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two-value mini card with a bar cluster on each side.
class _MiniSplitCard extends StatelessWidget {
  const _MiniSplitCard({
    required this.metrics,
    required this.leftColor,
    required this.rightColor,
  });

  final _MiniMetrics metrics;
  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final math.Random rng = math.Random(metrics.left.length);

    Widget bars(Color color, bool alignEnd) => SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: alignEnd
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(8, (int i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 3,
              height: math.max(10, rng.nextDouble() * 32),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );

    Widget metric(String label, String value, CrossAxisAlignment align) =>
        Column(
          crossAxisAlignment: align,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: _cardDecoration(context),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: metric(
                  metrics.left,
                  metrics.leftVal,
                  CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: metric(
                  metrics.right,
                  metrics.rightVal,
                  CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: bars(rightColor, false)),
              Expanded(child: bars(leftColor, true)),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Calculated Aggregate Trends" — the large dual-area chart.
class _AggregateTrendsCard extends StatelessWidget {
  const _AggregateTrendsCard({
    required this.total,
    required this.points,
    required this.metrics,
  });

  final int total;
  final List<TelemetryPoint> points;
  final _ChartMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    double maxY = 1;
    for (final TelemetryPoint p in points) {
      maxY = math.max(maxY, math.max(p.sales.toDouble(), p.orders.toDouble()));
    }

    Widget legend(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'CALCULATED AGGREGATE TRENDS',
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$total',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: <Widget>[
              legend(metrics.rightColor, metrics.left),
              legend(metrics.leftColor, metrics.right),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 240,
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'No activity in the last six months.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.3,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (double value) =>
                            FlLine(color: palette.border, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (double value, TitleMeta meta) =>
                                Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final int i = value.toInt();
                              if (i < 0 || i >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  points[i].name,
                                  style: TextStyle(
                                    color: palette.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (LineBarSpot spot) =>
                              palette.surface,
                        ),
                      ),
                      lineBarsData: <LineChartBarData>[
                        _band(
                          points.map((TelemetryPoint p) => p.sales).toList(),
                          metrics.leftColor,
                        ),
                        _band(
                          points.map((TelemetryPoint p) => p.orders).toList(),
                          metrics.rightColor,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _band(List<int> values, Color color) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < values.length; i++)
          FlSpot(i.toDouble(), values[i].toDouble()),
      ],
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// The 99.9% gauge widget.
class _AnalyticsGaugeCard extends StatelessWidget {
  const _AnalyticsGaugeCard({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Text(
                'LAST 30 DAYS ▾',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 84,
            width: 160,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 0,
                    centerSpaceRadius: 34,
                    sections: <PieChartSectionData>[
                      PieChartSectionData(
                        value: 72,
                        color: color,
                        radius: 22,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 28,
                        color: AppColors.warning,
                        radius: 22,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 100,
                        color: Colors.transparent,
                        radius: 22,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '99.9%',
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The gradient contact card.
class _EmailCard extends StatelessWidget {
  const _EmailCard({
    required this.title,
    required this.email,
    required this.gradient,
  });

  final String title;
  final String email;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: <Widget>[
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Server-health card with the decorative wave.
class _ServerHealthCard extends StatelessWidget {
  const _ServerHealthCard({
    required this.label,
    required this.status,
    required this.color,
  });

  final String label;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: Container(
        height: 150,
        decoration: _cardDecoration(context),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: -10,
              height: 90,
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(painter: _WavePainter(color)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      Text(
                        'LIVE ▾',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(0, size.height * 0.33)
      ..cubicTo(
        size.width * 0.3,
        size.height,
        size.width * 0.7,
        -size.height * 0.33,
        size.width,
        size.height * 0.33,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color;
}
