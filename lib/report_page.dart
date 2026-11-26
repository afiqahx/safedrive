import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'services/api_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.userID});

  final int userID;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  static const _blue = Color(0xFF2862E9);
  static const _navy = Color(0xFF142B4A);
  static const _muted = Color(0xFF718096);

  bool _loading = true;
  bool _exporting = false;
  bool _allRecords = false;
  String? _error;
  Map<String, dynamic> _report = {};

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport({bool? allRecords}) async {
    if (allRecords != null) {
      setState(() => _allRecords = allRecords);
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService.getReport(
      widget.userID,
      allRecords: _allRecords,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _report = result;
      } else {
        _error = result['message']?.toString() ?? 'Could not load report.';
      }
    });
  }

  int get _trips => _asInt(_report['totalTrips']);
  int get _alerts => _asInt(_report['totalAlerts']);
  int get _averageSeconds => _asInt(_report['averageTripSeconds']);
  int get _openEyes => _eyeCount('Open');
  int get _closedEyes => _eyeCount('Closed');
  int get _eyeEvents => _openEyes + _closedEyes;

  int _eyeCount(String stateName) {
    final rows = (_report['eyeStates'] as List?) ?? const [];
    for (final row in rows) {
      if (row is Map &&
          row['state']?.toString().toLowerCase() == stateName.toLowerCase()) {
        return _asInt(row['count']);
      }
    }
    return 0;
  }

  int _asInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<_AlertBucket> get _alertBuckets {
    final rows = (_report['alertBuckets'] as List?) ?? const [];
    if (_report['alertBucketType'] == 'month') {
      const monthLabels = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return rows.whereType<Map>().map((row) {
        final period = row['period']?.toString() ?? '';
        final date = DateTime.tryParse('$period-01');
        final label = date == null
            ? period
            : '${monthLabels[date.month - 1]} ${date.year.toString().substring(2)}';
        return _AlertBucket(label: label, count: _asInt(row['count']));
      }).toList();
    }

    final byDay = <String, int>{};
    for (final row in rows.whereType<Map>()) {
      byDay[row['period']?.toString() ?? ''] = _asInt(row['count']);
    }

    final today = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - index));
      final key = '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return _AlertBucket(
          label: labels[day.weekday - 1], count: byDay[key] ?? 0);
    });
  }

  String get _averageTripLabel {
    if (_averageSeconds == 0) return '0 min';
    final minutes = (_averageSeconds / 60).round();
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return remainingMinutes == 0
        ? '${hours}h'
        : '${hours}h ${remainingMinutes}m';
  }

  int _percent(int count) =>
      _eyeEvents == 0 ? 0 : (count * 100 / _eyeEvents).round();

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      final document = pw.Document();
      final rows = _alertBuckets;
      final rangeLabel = _allRecords ? 'All records' : 'Last 7 days';
      document.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text('SafeDrive Fatigue Report',
                style:
                    pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Report period: $rangeLabel'),
            pw.SizedBox(height: 20),
            pw.Text('Driving summary',
                style:
                    pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Measure', 'Recorded value'],
              data: [
                ['Completed trips', '$_trips'],
                ['Recorded alerts', '$_alerts'],
                ['Average trip duration', _averageTripLabel],
                ['Open-eye records', '$_openEyes (${_percent(_openEyes)}%)'],
                [
                  'Closed-eye records',
                  '$_closedEyes (${_percent(_closedEyes)}%)'
                ],
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
                _allRecords
                    ? 'Alert frequency by month'
                    : 'Alert frequency by day',
                style:
                    pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: [_allRecords ? 'Month' : 'Day', 'Alerts'],
              data: rows.map((item) => [item.label, '${item.count}']).toList(),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
                'Eye-state percentages use recorded Open and Closed events only.'),
          ],
        ),
      );
      final bytes = await document.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'safedrive_${_allRecords ? 'all_records' : 'last_7_days'}_report_${DateTime.now().toIso8601String().substring(0, 10)}.pdf',
      );
    } catch (error) {
      if (mounted)
        _showMessage('Could not export the report. Please try again.');
      debugPrint('REPORT PDF ERROR: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fatigue Report',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: _navy)),
                    SizedBox(height: 3),
                    Text('Safety analytics from your recorded trips',
                        style: TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
              PopupMenuButton<bool>(
                tooltip: 'Choose report period',
                onSelected: (value) => _loadReport(allRecords: value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: false, child: Text('Last 7 days')),
                  PopupMenuItem(value: true, child: Text('All records')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_allRecords ? 'All records' : 'Last 7 days',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _blue,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    const Icon(Icons.expand_more, size: 15, color: _blue),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const SizedBox(
                height: 280, child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _loadReport)
          else ...[
            Row(
              children: [
                Expanded(
                    child: _MetricCard(label: 'TOTAL TRIPS', value: '$_trips')),
                const SizedBox(width: 9),
                Expanded(
                    child: _MetricCard(
                        label: 'TOTAL ALERTS',
                        value: '$_alerts',
                        valueColor: const Color(0xFFE45252))),
                const SizedBox(width: 9),
                Expanded(
                    child: _MetricCard(
                        label: 'AVG TRIP', value: _averageTripLabel)),
              ],
            ),
            const SizedBox(height: 12),
            _EyeSummaryCard(
              closedPercent: _percent(_closedEyes),
              hasRecords: _eyeEvents > 0,
            ),
            const SizedBox(height: 12),
            _AlertChartCard(
              buckets: _alertBuckets,
              groupByMonth: _report['alertBucketType'] == 'month',
            ),
            const SizedBox(height: 12),
            _EyeRatioCard(
              openCount: _openEyes,
              closedCount: _closedEyes,
              openPercent: _percent(_openEyes),
              closedPercent: _percent(_closedEyes),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _exporting ? null : _exportPdf,
                icon: _exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded, size: 19),
                label: Text(_exporting
                    ? 'Preparing PDF...'
                    : 'Export Analytics Report PDF'),
                style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertBucket {
  const _AlertBucket({required this.label, required this.count});
  final String label;
  final int count;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      this.valueColor = const Color(0xFF142B4A)});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0D142B4A), blurRadius: 8, offset: Offset(0, 2))
            ]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 8,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 21,
                      color: valueColor,
                      fontWeight: FontWeight.w800))),
        ]),
      );
}

class _EyeSummaryCard extends StatelessWidget {
  const _EyeSummaryCard(
      {required this.closedPercent, required this.hasRecords});
  final int closedPercent;
  final bool hasRecords;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFE9FAF4),
            border: Border.all(color: const Color(0xFF9AEBCF)),
            borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('RECORDED EYE STATE',
                    style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF38A989),
                        fontWeight: FontWeight.bold,
                        letterSpacing: .4)),
                const SizedBox(height: 6),
                Text(
                    hasRecords
                        ? '$closedPercent% closed-eye events'
                        : 'No eye-state records',
                    style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF187D66),
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Based on recorded Open and Closed events',
                    style: TextStyle(fontSize: 10, color: Color(0xFF38A989))),
              ])),
          Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  color: Colors.white70, shape: BoxShape.circle),
              child: Center(
                  child: Text(hasRecords ? '$closedPercent%' : '—',
                      style: const TextStyle(
                          color: Color(0xFF18836A),
                          fontWeight: FontWeight.bold)))),
        ]),
      );
}

class _AlertChartCard extends StatelessWidget {
  const _AlertChartCard({required this.buckets, required this.groupByMonth});
  final List<_AlertBucket> buckets;
  final bool groupByMonth;

  Widget _bar(_AlertBucket bucket, int maxCount, {double? width}) {
    final barHeight = bucket.count == 0 ? 3.0 : 72 * bucket.count / maxCount;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (bucket.count > 0)
              Text('${bucket.count}',
                  style:
                      const TextStyle(fontSize: 9, color: Color(0xFF718096))),
            const Spacer(),
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: bucket.count == 0
                    ? const Color(0xFFE6ECF6)
                    : const Color(0xFF2862E9),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 6),
            Text(bucket.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: Color(0xFF718096))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = math.max(
      1,
      buckets.fold<int>(0, (value, bucket) => math.max(value, bucket.count)),
    );
    final bars = groupByMonth
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: buckets
                  .map((bucket) => _bar(bucket, maxCount, width: 58))
                  .toList(),
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buckets
                .map((bucket) => Expanded(child: _bar(bucket, maxCount)))
                .toList(),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D142B4A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupByMonth
                ? 'Alert Frequency by Month'
                : 'Alert Frequency History',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF142B4A),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 135,
            child: buckets.isEmpty
                ? const Center(
                    child: Text('No alert records found.',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF718096))),
                  )
                : bars,
          ),
          const Divider(height: 12, color: Color(0xFFE7ECF2)),
        ],
      ),
    );
  }
}

class _EyeRatioCard extends StatelessWidget {
  const _EyeRatioCard(
      {required this.openCount,
      required this.closedCount,
      required this.openPercent,
      required this.closedPercent});
  final int openCount;
  final int closedCount;
  final int openPercent;
  final int closedPercent;

  @override
  Widget build(BuildContext context) {
    final total = openCount + closedCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D142B4A), blurRadius: 8, offset: Offset(0, 2))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Eye State Event Ratio',
            style: TextStyle(
                fontSize: 13,
                color: Color(0xFF142B4A),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(children: [
          SizedBox(
              width: 84,
              height: 84,
              child: CustomPaint(
                  painter: _EyeDonutPainter(
                      openCount: openCount, closedCount: closedCount),
                  child: Center(
                      child: Text(total == 0 ? '—' : '$openPercent%',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF142B4A),
                              fontWeight: FontWeight.bold))))),
          const SizedBox(width: 18),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _LegendRow(
                    color: const Color(0xFF2862E9),
                    label: 'Eyes Open',
                    value: '$openPercent% ($openCount)'),
                const SizedBox(height: 9),
                _LegendRow(
                    color: const Color(0xFFE55353),
                    label: 'Eyes Closed',
                    value: '$closedPercent% ($closedCount)'),
                if (total == 0) ...[
                  const SizedBox(height: 8),
                  const Text('No eye-state records in this period.',
                      style: TextStyle(fontSize: 10, color: Color(0xFF718096))),
                ],
              ])),
        ]),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF142B4A)))),
        Text(value,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF52647C),
                fontWeight: FontWeight.w600)),
      ]);
}

class _EyeDonutPainter extends CustomPainter {
  const _EyeDonutPainter({required this.openCount, required this.closedCount});
  final int openCount;
  final int closedCount;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final background = Paint()
      ..color = const Color(0xFFE8EDF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, background);
    final total = openCount + closedCount;
    if (total == 0) return;
    final openPaint = Paint()
      ..color = const Color(0xFF2862E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final closedPaint = Paint()
      ..color = const Color(0xFFE55353)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final openSweep = math.pi * 2 * openCount / total;
    canvas.drawArc(rect, -math.pi / 2, openSweep, false, openPaint);
    if (closedCount > 0)
      canvas.drawArc(rect, -math.pi / 2 + openSweep,
          math.pi * 2 * closedCount / total, false, closedPaint);
  }

  @override
  bool shouldRepaint(covariant _EyeDonutPainter oldDelegate) =>
      openCount != oldDelegate.openCount ||
      closedCount != oldDelegate.closedCount;
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 300,
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF52647C))),
        const SizedBox(height: 14),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ])));
}
