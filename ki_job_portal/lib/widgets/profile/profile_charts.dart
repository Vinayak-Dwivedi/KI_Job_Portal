import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/profile_stats_provider.dart';
import '../../providers/review_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import 'reviews_list_sheet.dart';

class ProfileCharts extends ConsumerWidget {
  final String uid;
  final bool isOwner;
  const ProfileCharts({super.key, required this.uid, this.isOwner = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider(uid));

    return statsAsync.when(
      data: (stats) => _buildCharts(context, ref, stats),
      loading: () => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('Could not load stats', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }

  Widget _buildCharts(BuildContext context, WidgetRef ref, ProfileStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary Cards Row ────────────────────────────────────────────
        _buildSummaryRow(context, ref, stats),
        const SizedBox(height: 24),

        // ── Earnings Trend Chart ─────────────────────────────────────────
        _EarningsChart(data: stats.earningsTrend)
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.05, end: 0),
        const SizedBox(height: 20),

        // ── Job Activity Chart ───────────────────────────────────────────
        _JobActivityChart(data: stats.jobActivity)
            .animate()
            .fadeIn(duration: 500.ms, delay: 100.ms)
            .slideY(begin: 0.05, end: 0),
        const SizedBox(height: 20),

        // ── Rating Breakdown ─────────────────────────────────────────────
        _RatingBreakdownChart(
          breakdown: stats.ratingBreakdown,
          average: stats.averageRating,
          total: stats.totalReviews,
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideY(begin: 0.05, end: 0),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, WidgetRef ref, ProfileStats stats) {
    return Row(
      children: [
        if (isOwner) ...[
          Expanded(
            child: _SummaryCard(
              icon: Icons.toll_rounded,
              value: '${stats.currentBalance}',
              label: 'Credits',
              color: const Color(0xFFFBBF24),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: _SummaryCard(
            icon: Icons.work_outline_rounded,
            value: '${stats.totalJobsCompleted}',
            label: 'Posts',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            onTap: () => _showReviewsSheet(context, ref),
            icon: Icons.star_rounded,
            value: stats.averageRating > 0
                ? stats.averageRating.toStringAsFixed(1)
                : '—',
            label: '${stats.totalReviews} Reviews',
            color: Colors.orange,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showReviewsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReviewsListSheet(uid: uid),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(theme.brightness == Brightness.dark ? 0.08 : 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EARNINGS TREND (LINE CHART)
// ═══════════════════════════════════════════════════════════════════════════════

class _EarningsChart extends StatelessWidget {
  final List<MonthlyData> data;
  const _EarningsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasData = data.any((d) => d.value > 0);

    return _ChartContainer(
      title: l10n.creditActivity,
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFF10B981),
      child: hasData ? _buildChart(context) : _buildEmptyState(l10n.noCreditActivity),
    );
  }

  Widget _buildChart(BuildContext context) {
    final values = data.map((d) => d.value).toList();
    final maxY = values.isEmpty ? 10.0 : values.reduce(max) * 1.3;
    final safeMaxY = maxY <= 0 ? 10.0 : maxY;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          clipData: const FlClipData.all(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[idx].label,
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: safeMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFF10B981),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF10B981),
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).cardColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.25),
                    const Color(0xFF10B981).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()} cr',
                    GoogleFonts.plusJakartaSans(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// JOB ACTIVITY (BAR CHART)
// ═══════════════════════════════════════════════════════════════════════════════

class _JobActivityChart extends StatelessWidget {
  final List<MonthlyData> data;
  const _JobActivityChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasData = data.any((d) => d.value > 0);

    return _ChartContainer(
      title: l10n.workActivity,
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.primary,
      child: hasData ? _buildChart(context) : _buildEmptyState(l10n.noWorkActivity),
    );
  }

  Widget _buildChart(BuildContext context) {
    final values = data.map((d) => d.value).toList();
    final maxY = values.isEmpty ? 5.0 : values.reduce(max) * 1.4;
    final safeMaxY = maxY <= 0 ? 5.0 : maxY;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[idx].label,
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          maxY: safeMaxY,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF60A5FA)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} posts',
                  GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RATING BREAKDOWN
// ═══════════════════════════════════════════════════════════════════════════════

class _RatingBreakdownChart extends StatelessWidget {
  final List<RatingDistribution> breakdown;
  final double average;
  final int total;

  const _RatingBreakdownChart({
    required this.breakdown,
    required this.average,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ChartContainer(
      title: l10n.ratingsAndReviews,
      icon: Icons.star_rounded,
      iconColor: Colors.orange,
      child: total == 0
          ? _buildEmptyState(l10n.noReviewsYet)
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final counts = breakdown.map((r) => r.count).toList();
    final maxCount = counts.isEmpty ? 1 : counts.reduce(max);
    final safeMax = maxCount <= 0 ? 1 : maxCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average Rating Display
        Column(
          children: [
            Text(
              average.toStringAsFixed(1),
              style: GoogleFonts.plusJakartaSans(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Row(
              children: List.generate(5, (i) {
                return Icon(
                i < average.round() ? Icons.star_rounded : Icons.star_border_rounded,
                color: theme.brightness == Brightness.dark ? Colors.orange : Colors.orange.shade700,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              '$total reviews',
              style: GoogleFonts.plusJakartaSans(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),

        // Bar breakdown
        Expanded(
          child: Column(
            children: breakdown.map((r) {
              final fraction = r.count / safeMax;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      child: Text(
                        '${r.star}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _starColor(r.star),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${r.count}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _starColor(int star) {
    switch (star) {
      case 5:
        return const Color(0xFF10B981);
      case 4:
        return const Color(0xFF34D399);
      case 3:
        return const Color(0xFFFBBF24);
      case 2:
        return const Color(0xFFF97316);
      case 1:
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED CHART CONTAINER
// ═══════════════════════════════════════════════════════════════════════════════

class _ChartContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ChartContainer({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: theme.brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════════

Widget _buildEmptyState(String message) {
  return SizedBox(
    height: 100,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 32, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey.withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

