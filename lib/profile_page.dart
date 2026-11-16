import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF142B4A),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: const [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFF2878D0),
                      child: Icon(
                        Icons.person,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Driver',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF142B4A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const ListTile(
                leading: Icon(Icons.badge_outlined),
                title: Text('User ID'),
                trailing: Text('U001'),
              ),
              const ListTile(
                leading: Icon(Icons.phone_outlined),
                title: Text('Phone'),
                trailing: Text('+1 555 123 4567'),
              ),
              const ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Preferences'),
                trailing: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
