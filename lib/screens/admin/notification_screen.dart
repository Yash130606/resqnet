import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'New SOS Alert!',
      'body': 'Flood Emergency reported at Sector 4',
      'time': '2 mins ago',
      'icon': Icons.warning_amber,
      'color': Colors.red,
      'read': false,
    },
    {
      'title': 'Volunteer Assigned',
      'body': 'A volunteer has been assigned to the case',
      'time': '15 mins ago',
      'icon': Icons.volunteer_activism,
      'color': Colors.green,
      'read': false,
    },
    {
      'title': 'Emergency Resolved',
      'body': 'Medical request marked as resolved',
      'time': '1 hour ago',
      'icon': Icons.check_circle,
      'color': Colors.green,
      'read': true,
    },
    {
      'title': 'Weather Alert',
      'body': 'Heavy rainfall expected tonight',
      'time': '2 hours ago',
      'icon': Icons.cloud,
      'color': Colors.blue,
      'read': true,
    },
    {
      'title': 'System Update',
      'body': 'ResQNet updated with new features',
      'time': '1 day ago',
      'icon': Icons.system_update,
      'color': Colors.orange,
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((n) => n['read'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n['read'] = true;
                  }
                });
              },
              child: const Text(
                "Mark all read",
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 16),
              color: const Color(0xFFD32F2F).withOpacity(0.15),
              child: Text(
                "$unreadCount unread notification${unreadCount > 1 ? 's' : ''}",
                style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            color: Colors.grey, size: 60),
                        SizedBox(height: 12),
                        Text(
                          "No notifications",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];

                      return Dismissible(
                        key: Key(index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:
                              const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() {
                            _notifications.removeAt(index);
                          });
                        },
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              notif['read'] = true;
                            });
                          },
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notif['read']
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFF2A2A2A),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: notif['read']
                                  ? null
                                  : Border.all(
                                      color: const Color(
                                              0xFFD32F2F)
                                          .withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: (notif['color']
                                            as Color)
                                        .withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    notif['icon']
                                        as IconData,
                                    color: notif['color']
                                        as Color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif['title'],
                                              style:
                                                  TextStyle(
                                                color: Colors
                                                    .white,
                                                fontWeight:
                                                    notif['read']
                                                        ? FontWeight
                                                            .normal
                                                        : FontWeight
                                                            .bold,
                                              ),
                                            ),
                                          ),
                                          if (!notif['read'])
                                            const Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: Color(
                                                  0xFFD32F2F),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['body'],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['time'],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}