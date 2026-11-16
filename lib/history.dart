import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'template.dart';

class HistoryPage extends StatefulWidget {
  final int userID;

  const HistoryPage({
    super.key,
    required this.userID,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  //trip history
  Future<void> loadTrips() async {
    setState(() {
      isLoading = true;
    });

    final result = await ApiService.getTrips(widget.userID);

    if (!mounted) return;

    setState(() {
      trips = result;
      isLoading = false;
    });
  }

  //date format
  String formatDate(dynamic value) {
    if (value == null) return 'Unknown date';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (e) {
      return value.toString();
    }
  }

  String formatTime(dynamic value) {
    if (value == null) return '--:--';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '$hour:$minute $period';
    } catch (e) {
      return '--:--';
    }
  }

  //duration format
  String formatDuration(dynamic value) {
    final seconds = int.tryParse(value?.toString() ?? '') ?? 0;

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${minutes}m';
  }

  //delete trip
  Future<void> deleteTrip(int tripID) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
          'Are you sure you want to delete this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ApiService.deleteTrip(tripID);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
      ),
    );

    if (result['success'] == true) {
      loadTrips();
    }
  }

  ///edit trip
  Future<void> editTrip(Map<String, dynamic> trip) async {
    final tripID = int.parse(trip['tripID'].toString());

    final durationController = TextEditingController(
      text: ((int.tryParse(
                    trip['durationSeconds']?.toString() ?? '0',
                  ) ??
                  0) ~/
              60)
          .toString(),
    );

    final alertsController = TextEditingController(
      text: trip['totalAlerts']?.toString() ?? '0',
    );

    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Trip'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) < 0) {
                    return 'Enter a valid duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: alertsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Alerts',
                ),
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) < 0) {
                    return 'Enter a valid alert count';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final durationMinutes = int.parse(durationController.text);

    final totalAlerts = int.parse(alertsController.text);

    final result = await ApiService.updateTrip(
      tripID: tripID,
      startTime: trip['startTime'].toString(),
      endTime: trip['endTime'].toString(),
      durationSeconds: durationMinutes * 60,
      totalAlerts: totalAlerts,
      tripStatus: trip['tripStatus'] ?? 'Completed',
    );

    durationController.dispose();
    alertsController.dispose();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
      ),
    );

    if (result['success'] == true) {
      loadTrips();
    }
  }

  //trip card widget
  Widget buildTripCard(Map<String, dynamic> trip) {
    final tripID = int.parse(trip['tripID'].toString());

    final duration = formatDuration(
      trip['durationSeconds'],
    );

    final alerts = trip['totalAlerts'] ?? 0;

    final status = trip['tripStatus'] ?? 'Completed';

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailPage(
                trip: trip,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppColors.blue,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip #$tripID',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(trip['startTime']),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        editTrip(trip);
                      } else if (value == 'delete') {
                        deleteTrip(tripID);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _tripInfo(
                      Icons.access_time,
                      'Duration',
                      duration,
                    ),
                  ),
                  Expanded(
                    child: _tripInfo(
                      Icons.warning_amber_rounded,
                      'Alerts',
                      alerts.toString(),
                    ),
                  ),
                  Expanded(
                    child: _tripInfo(
                      Icons.flag_outlined,
                      'Status',
                      status.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppColors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripInfo(
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget buildSummary() {
    final totalAlerts = trips.fold<int>(
      0,
      (sum, trip) =>
          sum +
          (int.tryParse(
                trip['totalAlerts']?.toString() ?? '0',
              ) ??
              0),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              'Total Trips',
              trips.length.toString(),
              Icons.directions_car,
            ),
          ),
          Container(
            width: 1,
            height: 45,
            color: Colors.white24,
          ),
          Expanded(
            child: _summaryItem(
              'Total Alerts',
              totalAlerts.toString(),
              Icons.warning_amber_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 23,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Trip History Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed driving sessions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //histry page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: loadTrips,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : trips.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      buildEmptyState(),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Trip History',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review your previous driving sessions.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildSummary(),
                      const SizedBox(height: 24),
                      const Text(
                        'Recent Trips',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...trips.map(buildTripCard),
                    ],
                  ),
      ),
    );
  }
}

///trip detail page
class TripDetailPage extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailPage({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  List<Map<String, dynamic>> alerts = [];

  bool isLoading = true;

  int get tripID => int.parse(widget.trip['tripID'].toString());

  @override
  void initState() {
    super.initState();
    loadAlerts();
  }

  //alert history
  Future<void> loadAlerts() async {
    setState(() {
      isLoading = true;
    });

    final result = await ApiService.getTripAlerts(tripID);

    if (!mounted) return;

    setState(() {
      alerts = result;
      isLoading = false;
    });
  }

  String formatDateTime(dynamic value) {
    if (value == null) return 'Unknown';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}  $hour:$minute $period';
    } catch (e) {
      return value.toString();
    }
  }

  //alert card
  Widget buildAlertCard(Map<String, dynamic> alert) {
    final level = alert['drowsinessLevel']?.toString() ?? 'Unknown';

    final alertType = alert['alertType']?.toString() ?? 'Alert';

    final eyeState = alert['eyeState']?.toString() ?? 'Not available';

    final confidence = alert['confidence'];

    final closureDuration = alert['closureDuration'];

    final alertID = alert['alertID'];

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlertVideoPage(
                tripID: tripID,
                alert: alert,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 25,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$alertType - $level',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '#$alertID',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert['message']?.toString() ?? 'Drowsiness detected.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              _detailRow(
                'Alert Time',
                formatDateTime(alert['alertTime']),
              ),
              _detailRow(
                'Eye State',
                eyeState,
              ),
              _detailRow(
                'Confidence',
                confidence == null ? 'Not available' : '$confidence',
              ),
              _detailRow(
                'Closure Duration',
                closureDuration == null
                    ? 'Not available'
                    : '$closureDuration seconds',
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Video Details',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.play_circle_outline,
                    color: AppColors.blue,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //trip details
  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Trip Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip #$tripID',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _whiteDetail(
                  'Start Time',
                  formatDateTime(trip['startTime']),
                ),
                _whiteDetail(
                  'End Time',
                  formatDateTime(trip['endTime']),
                ),
                _whiteDetail(
                  'Duration',
                  '${trip['durationSeconds'] ?? 0} seconds',
                ),
                _whiteDetail(
                  'Total Alerts',
                  '${trip['totalAlerts'] ?? 0}',
                ),
                _whiteDetail(
                  'Status',
                  '${trip['tripStatus'] ?? 'Unknown'}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Detection & Alert History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Review drowsiness alerts detected during this trip.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade400,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No Alerts Recorded',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'No drowsiness alerts were recorded for this trip.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...alerts.map(buildAlertCard),
        ],
      ),
    );
  }

  Widget _whiteDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
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

// alert video page
class AlertVideoPage extends StatefulWidget {
  final int tripID;
  final Map<String, dynamic> alert;

  const AlertVideoPage({
    super.key,
    required this.tripID,
    required this.alert,
  });

  @override
  State<AlertVideoPage> createState() => _AlertVideoPageState();
}

class _AlertVideoPageState extends State<AlertVideoPage> {
  Map<String, dynamic>? videoData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVideo();
  }

  //load video data for the trip
  Future<void> loadVideo() async {
    final result = await ApiService.getTripVideo(
      widget.tripID,
    );

    if (!mounted) return;

    setState(() {
      videoData = result;
      isLoading = false;
    });
  }

  //alert time offset from video start
  String getVideoOffset() {
    if (videoData == null ||
        videoData!['videoStartTime'] == null ||
        widget.alert['alertTime'] == null) {
      return 'Not available';
    }

    try {
      final videoStart = DateTime.parse(
        videoData!['videoStartTime'].toString(),
      );

      final alertTime = DateTime.parse(
        widget.alert['alertTime'].toString(),
      );

      final difference = alertTime.difference(videoStart);

      if (difference.isNegative) {
        return 'Alert occurred before video start';
      }

      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;

      return '${minutes}m ${seconds}s';
    } catch (e) {
      return 'Not available';
    }
  }

  //video placement
  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Alert Video',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 65,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Video Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Video playback will be available\nwhen a recording is stored.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Alert Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _videoDetail(
            'Alert Type',
            alert['alertType']?.toString() ?? 'Unknown',
          ),
          _videoDetail(
            'Drowsiness Level',
            alert['drowsinessLevel']?.toString() ?? 'Unknown',
          ),
          _videoDetail(
            'Alert Time',
            alert['alertTime']?.toString() ?? 'Unknown',
          ),
          _videoDetail(
            'Eye State',
            alert['eyeState']?.toString() ?? 'Unknown',
          ),
          _videoDetail(
            'Confidence',
            alert['confidence']?.toString() ?? 'Not available',
          ),
          _videoDetail(
            'Closure Duration',
            alert['closureDuration']?.toString() ?? 'Not available',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _videoDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
