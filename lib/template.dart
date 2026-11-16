import 'package:flutter/material.dart';

// APP COLOURS
class AppColors {
  static const navy = Color(0xFF142B4A);
  static const blue = Color(0xFF2878D0);
  static const background = Color(0xFFF7F9FC);
  static const grey = Color(0xFF7A8795);
}

class Template extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Template({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      //header / app bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 18,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.blue,
              child: Icon(
                Icons.directions_car_rounded,
                size: 19,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLINK',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  'Your Drive Monitor',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        /**actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: RPiStatusBadge(),
            ),
          ),
        ],**/
      ),

      // page body
      body: body,

      // footer / bottom navigation bar
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: selectedIndex,
        onDestinationSelected: onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/** RASPBERRY PI STATUS
class RPiStatusBadge extends StatelessWidget {
  const RPiStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FBF3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        '● RPi: Can Active',
        style: TextStyle(
          fontSize: 10,
          color: Color(0xFF178A68),
        ),
      ),
    );
  }
}**/
