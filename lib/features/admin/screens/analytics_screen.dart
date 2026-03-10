import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final notifier = ref.read(analyticsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics & Intelligence',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  Text('Platform performance overview',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white38,
                      )),
                ],
              ),
              const Spacer(),
              // Filter row
              _FilterDropdown(
                label: 'Category',
                value: state.filterCategory,
                items: const ['All', 'Agriculture', 'Healthcare', 'Energy', 'Construction', 'Product Design', 'Information Technology'],
                onChanged: notifier.setFilterCategory,
              ),
              const SizedBox(width: 10),
              _FilterDropdown(
                label: 'Status',
                value: state.filterStatus,
                items: const ['All', 'Approved', 'Pending', 'Rejected'],
                onChanged: notifier.setFilterStatus,
              ),
              const SizedBox(width: 10),
              _ExportButton(),
            ],
          ),

          const SizedBox(height: 28),

          const _SectionHeader(title: 'Engagement & Activity'),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStatCard(label: 'Daily Active Users', value: '${state.dau}', icon: Icons.online_prediction_rounded, color: AppColors.teal),
              const SizedBox(width: 16),
              _MiniStatCard(label: 'Monthly Active Users', value: '${state.mau}', icon: Icons.calendar_month_rounded, color: AppColors.sky),
              const SizedBox(width: 16),
              _MiniStatCard(label: 'Inactive 30d', value: '${state.inactiveUsers30}', icon: Icons.person_off_rounded, color: AppColors.golden),
              const SizedBox(width: 16),
              _MiniStatCard(label: 'Inactive 60d', value: '${state.inactiveUsers60}', icon: Icons.person_off_rounded, color: AppColors.crimson),
              const SizedBox(width: 16),
              _MiniStatCard(label: 'Inactive 90d+', value: '${state.inactiveUsers90}', icon: Icons.person_off_rounded, color: Colors.red.shade900),
            ],
          ),

          const SizedBox(height: 28),

          const _SectionHeader(title: 'User Growth Analytics'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stacked bar chart
              Expanded(
                flex: 3,
                child: _DarkCard(
                  title: 'New Registrations by Role (Monthly)',
                  child: SizedBox(
                    height: 220,
                    child: _UserGrowthChart(data: state.userGrowth),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // MoM change
              Expanded(
                child: _DarkCard(
                  title: 'Month-over-Month',
                  child: _MoMStats(data: state.userGrowth),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _SectionHeader(title: 'Most Active Users Leaderboard'),
          const SizedBox(height: 16),
          _DarkCard(
            title: 'Leaderboard',
            trailing: _LeaderboardMetricSelector(
              selected: state.selectedLeaderboardMetric,
              onSelect: notifier.setLeaderboardMetric,
            ),
            child: _LeaderboardTable(entries: state.leaderboard),
          ),

          const SizedBox(height: 28),

          const _SectionHeader(title: 'Top Products'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _DarkCard(
                  title: 'Top Products by Engagement',
                  child: _TopProductsTable(products: state.topProducts),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DarkCard(
                  title: 'Category Engagement',
                  child: SizedBox(
                    height: 280,
                    child: _CategoryPieChart(products: state.topProducts),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _SectionHeader(title: 'Login Frequency Distribution'),
          const SizedBox(height: 16),
          _DarkCard(
            title: 'Logins per Week',
            child: SizedBox(
              height: 180,
              child: _LoginFreqChart(),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            )),
      ],
    );
  }
}

// ─── DARK CARD ────────────────────────────────────────────────────────────────
class _DarkCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _DarkCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  )),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─── MINI STAT CARD ───────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151F2B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      )),
                  Text(label,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── USER GROWTH CHART ────────────────────────────────────────────────────────
class _UserGrowthChart extends StatelessWidget {
  final List<UserGrowthData> data;
  const _UserGrowthChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        alignment: BarChartAlignment.spaceAround,
        maxY: 30,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1E2D3D),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = data[groupIndex];
              return BarTooltipItem(
                '${d.month}\nInnovators: ${d.innovators}\nClients: ${d.clients}',
                const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
              reservedSize: 28,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx >= 0 && idx < data.length) {
                  return Text(data[idx].month,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white54,
                      ));
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: d.innovators.toDouble(),
                color: AppColors.teal,
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: d.clients.toDouble(),
                color: AppColors.sky,
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── MoM STATS ────────────────────────────────────────────────────────────────
class _MoMStats extends StatelessWidget {
  final List<UserGrowthData> data;
  const _MoMStats({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox();
    final last = data.last;
    final prev = data[data.length - 2];
    final totalLast = last.total;
    final totalPrev = prev.total;
    final pct = totalPrev > 0
        ? ((totalLast - totalPrev) / totalPrev * 100).toStringAsFixed(1)
        : '0';
    final positive = totalLast >= totalPrev;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MoMRow(label: 'This month', value: '$totalLast users', positive: true),
        const SizedBox(height: 12),
        _MoMRow(label: 'Last month', value: '$totalPrev users', positive: true),
        const SizedBox(height: 12),
        _MoMRow(
          label: 'Growth rate',
          value: '${positive ? '+' : ''}$pct%',
          positive: positive,
        ),
        const SizedBox(height: 12),
        _MoMRow(label: 'Innovators', value: '${last.innovators}', positive: true, color: AppColors.teal),
        const SizedBox(height: 8),
        _MoMRow(label: 'Clients', value: '${last.clients}', positive: true, color: AppColors.sky),
        const SizedBox(height: 8),
        _MoMRow(label: 'Deactivations', value: '${last.deactivations}', positive: last.deactivations == 0, color: AppColors.crimson),
      ],
    );
  }
}

class _MoMRow extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;
  final Color? color;

  const _MoMRow({
    required this.label,
    required this.value,
    required this.positive,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white38,
            )),
        Text(value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? (positive ? AppColors.teal : AppColors.crimson),
            )),
      ],
    );
  }
}

// ─── LEADERBOARD METRIC SELECTOR ─────────────────────────────────────────────
class _LeaderboardMetricSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _LeaderboardMetricSelector({
    required this.selected,
    required this.onSelect,
  });

  static const _metrics = [
    ('most_products', 'Most Products Uploaded'),
    ('most_approved', 'Most Products Approved'),
    ('most_interest', 'Most Interests Sent'),
    ('most_liked', 'Most Likes Given'),
    ('most_liked_innovator', 'Most Liked Innovator'),
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selected,
      dropdownColor: const Color(0xFF1E2D3D),
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: Colors.white70,
      ),
      underline: const SizedBox(),
      items: _metrics
          .map((m) => DropdownMenuItem(value: m.$1, child: Text(m.$2)))
          .toList(),
      onChanged: (v) => onSelect(v ?? selected),
    );
  }
}

// ─── LEADERBOARD TABLE ────────────────────────────────────────────────────────
class _LeaderboardTable extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _LeaderboardTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white38, fontFamily: 'Poppins')),
      );
    }
    return Column(
      children: entries.map((e) {
        final roleColor = e.role == 'innovator' ? AppColors.teal : AppColors.sky;
        final medalColor = e.rank == 1
            ? AppColors.golden
            : e.rank == 2
                ? Colors.grey.shade400
                : e.rank == 3
                    ? const Color(0xFFCD7F32)
                    : Colors.white24;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: e.rank == 1
                ? AppColors.golden.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: e.rank == 1
                  ? AppColors.golden.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: Text(
                  e.rank <= 3 ? ['🥇', '🥈', '🥉'][e.rank - 1] : '#${e.rank}',
                  style: TextStyle(fontSize: e.rank <= 3 ? 18 : 13, color: medalColor),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  e.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )),
                    Text('@${e.username}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white38,
                        )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.role.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${e.value}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(e.metric,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white38,
                      )),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── TOP PRODUCTS TABLE ───────────────────────────────────────────────────────
class _TopProductsTable extends StatelessWidget {
  final List<TopProduct> products;
  const _TopProductsTable({required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(flex: 3, child: _TH('Product')),
              Expanded(child: _TH('❤️ Likes')),
              Expanded(child: _TH('👁 Views')),
              Expanded(child: _TH('🤝 Interest')),
              SizedBox(width: 60, child: _TH('Trend')),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 8),
        ...products.map((p) {
          final color = AppColors.categoryColors[p.category] ?? AppColors.navy;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis),
                            Text(p.innovator,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Colors.white38,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _TV('${p.likes}', AppColors.crimson)),
                Expanded(child: _TV('${p.views}', Colors.white54)),
                Expanded(child: _TV('${p.interests}', AppColors.teal)),
                SizedBox(
                  width: 60,
                  child: p.rising
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up_rounded, color: AppColors.teal, size: 12),
                              SizedBox(width: 2),
                              Text('Rising', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: AppColors.teal, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      : const Text('—', style: TextStyle(color: Colors.white24)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600));
}

class _TV extends StatelessWidget {
  final String text;
  final Color color;
  const _TV(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: color));
}

// ─── CATEGORY PIE CHART ───────────────────────────────────────────────────────
class _CategoryPieChart extends StatelessWidget {
  final List<TopProduct> products;
  const _CategoryPieChart({required this.products});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> catLikes = {};
    for (final p in products) {
      catLikes[p.category] = (catLikes[p.category] ?? 0) + p.likes;
    }
    final total = catLikes.values.fold(0, (a, b) => a + b);
    final sections = catLikes.entries.map((e) {
      final color = AppColors.categoryColors[e.key] ?? AppColors.navy;
      final pct = total > 0 ? e.value / total * 100 : 0.0;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: 60,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: sections,
            sectionsSpace: 3,
            centerSpaceRadius: 40,
          )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: catLikes.entries.map((e) {
            final color = AppColors.categoryColors[e.key] ?? AppColors.navy;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                const SizedBox(width: 4),
                Text(e.key.split(' ').first,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white54)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── LOGIN FREQUENCY CHART ────────────────────────────────────────────────────
class _LoginFreqChart extends StatelessWidget {
  final _data = const [18, 34, 42, 28, 15, 9, 6];
  final _labels = const ['0-1x', '2-3x', '4-5x', '6-7x', '8-10x', '11-14x', '15x+'];

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        alignment: BarChartAlignment.spaceAround,
        maxY: 50,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i >= 0 && i < _labels.length) {
                  return Text(_labels[i],
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.white38));
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) => Text(val.toInt().toString(),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.white38)),
              reservedSize: 24,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.toDouble(),
                color: AppColors.sky,
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── FILTER DROPDOWN ──────────────────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1E2D3D),
        underline: const SizedBox(),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white70),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: (v) => onChanged(v ?? value),
      ),
    );
  }
}

// ─── EXPORT BUTTON ────────────────────────────────────────────────────────────
class _ExportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSV export initiated — file will download shortly.',
                style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.teal, size: 16),
            SizedBox(width: 6),
            Text('Export CSV',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal)),
          ],
        ),
      ),
    );
  }
}