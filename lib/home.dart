import 'package:flutter/material.dart';
import 'template.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 25),
      child: Column(
        children: [
          // LIVE DETECTION FEED
          _buildDetectionCard(),

          const SizedBox(height: 18),

          // MONITORING SESSION
          _buildSessionCard(),
        ],
      ),
    );
  }

  // LIVE DETECTION CARD
  Widget _buildDetectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD HEADER
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: AppColors.blue,
                size: 20,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Live Detection Feed',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '0 FPS',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // CAMERA DISPLAY PLACEHOLDER
          Container(
            width: double.infinity,
            height: 185,
            decoration: BoxDecoration(
              color: const Color(0xFF101B30),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // CAMERA OFF ICON
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: const Color(0xFF253650),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.videocam_off_rounded,
                        color: Color(0xFF8999B0),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Camera is Off',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Waiting for camera connection',
                      style: TextStyle(
                        color: Color(0xFF8999B0),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                // CAMERA OFF STATUS
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A2730),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: Color(0xFFE56B78),
                          size: 7,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'OFFLINE',
                          style: TextStyle(
                            color: Color(0xFFE56B78),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // DETECTION CONFIDENCE
          _infoRow(
            'Detection Confidence',
            '0.0%',
          ),

          const SizedBox(height: 7),

          // EYE CLOSURE TIMER
          _infoRow(
            'Closure Timer',
            '0.0 / 2.0 s',
          ),

          const SizedBox(height: 18),

          const Divider(height: 1, color: Color(0xFFEDF0F4)),

          const SizedBox(height: 14),

          // SAFETY MESSAGE
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF159E7B),
                size: 17,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Drive safe. Stay focused on the road!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF438D78),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MONITORING SESSION CARD
  Widget _buildSessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // SESSION HEADER
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MONITORING SESSION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9299A8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ID:0',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          // SESSION TIMER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '00:00:00',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColors.navy,
              ),
            ),
          ),

          const SizedBox(height: 17),

          // SESSION STATUS
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: Color(0xFFD1D8E0),
              ),
              SizedBox(width: 8),
              Text(
                'Ready for Trip',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          const Divider(height: 1, color: Color(0xFFEDF0F4)),

          const SizedBox(height: 12),

          // TOTAL ALERTS
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Alerts Detected:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // WIFI STATUS
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi,
                color: Color(0xFF438D78),
                size: 22,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Auto-starts when WiFi is detected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF438D78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // EYE ICON PLACEHOLDER
  Widget _buildEye() {
    return Container(
      width: 29,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF54D9B0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF54D9B0).withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  // CAMERA CORNER MARKERS
  Widget _cornerMarker(bool top, bool left) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left),
      ),
    );
  }

  // INFORMATION ROW
  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// CAMERA CORNER PAINTER
class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;

  _CornerPainter({
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5594E8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}
