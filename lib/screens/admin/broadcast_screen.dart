import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendBroadcast() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    await FirebaseFirestore.instance.collection('broadcasts').add({
      'message': _messageController.text.trim(),
      'active': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => _isSending = false);

    _messageController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearBroadcasts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('broadcasts').get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'active': false});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All broadcasts cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Emergency Broadcast',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter emergency message...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSending ? null : _sendBroadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SEND BROADCAST',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _clearBroadcasts,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
                child: const Text('CLEAR ALL BROADCASTS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
