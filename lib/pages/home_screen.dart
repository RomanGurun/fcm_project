import 'package:fcm_flutter/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FCMService _fcm = FCMService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _newsSubscribed = false;
  bool _offersSubscribed = false;
  bool _alertsSubscribed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _copyToken() {
    final token = _fcm.fcmToken;
    if (token == null) return;
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Token copied to clipboard!'),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _toggleTopic(String topic, bool current) async {
    if (current) {
      await _fcm.unsubscribeFromTopic(topic);
    } else {
      await _fcm.subscribeToTopic(topic);
    }

    setState(() {
      switch (topic) {
        case 'news':
          _newsSubscribed = !current;
          break;
        case 'offers':
          _offersSubscribed = !current;
          break;
        case 'alerts':
          _alertsSubscribed = !current;
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          current ? 'Unsubscribed from "$topic"' : 'Subscribed to "$topic"',
        ),
        backgroundColor:
            current ? Colors.red.shade800 : const Color(0xFF00E5A0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = _fcm.fcmToken;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5A0),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FCM Demo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            icon:
                const Icon(Icons.notifications_outlined, color: Colors.white70),
            tooltip: 'Notification History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── FCM Token Card ───────────────────────────────────────
            _SectionLabel(label: 'DEVICE TOKEN'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phonelink_lock,
                          color: Color(0xFF6C63FF), size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'FCM Registration Token',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      if (token != null)
                        GestureDetector(
                          onTap: _copyToken,
                          child: const Icon(Icons.copy,
                              color: Colors.white38, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (token == null)
                    const Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Fetching token...',
                            style: TextStyle(color: Colors.white38)),
                      ],
                    )
                  else
                    SelectableText(
                      token,
                      style: const TextStyle(
                        color: Color(0xFF00E5A0),
                        fontSize: 11,
                        height: 1.6,
                        letterSpacing: 0.5,
                      ),
                    ),
                  if (token != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _copyToken,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy Token'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6C63FF),
                          side: const BorderSide(color: Color(0xFF6C63FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── Topic Subscriptions ──────────────────────────────────
            _SectionLabel(label: 'TOPIC SUBSCRIPTIONS'),
            const SizedBox(height: 10),
            _TopicTile(
              topic: 'news',
              label: 'News',
              icon: Icons.newspaper_outlined,
              color: const Color(0xFF4FC3F7),
              subscribed: _newsSubscribed,
              onToggle: () => _toggleTopic('news', _newsSubscribed),
            ),
            const SizedBox(height: 10),
            _TopicTile(
              topic: 'offers',
              label: 'Offers & Deals',
              icon: Icons.local_offer_outlined,
              color: const Color(0xFFFFD54F),
              subscribed: _offersSubscribed,
              onToggle: () => _toggleTopic('offers', _offersSubscribed),
            ),
            const SizedBox(height: 10),
            _TopicTile(
              topic: 'alerts',
              label: 'System Alerts',
              icon: Icons.warning_amber_outlined,
              color: const Color(0xFFEF9A9A),
              subscribed: _alertsSubscribed,
              onToggle: () => _toggleTopic('alerts', _alertsSubscribed),
            ),

            const SizedBox(height: 30),

            // ── How to Test ──────────────────────────────────────────
            _SectionLabel(label: 'HOW TO TEST'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _TestStep(
                    number: '1',
                    text:
                        'Copy your FCM token above and go to Firebase Console → Cloud Messaging.',
                  ),
                  _TestStep(
                    number: '2',
                    text:
                        'Click "Send your first message", enter a title & body, then target this specific device by pasting the token.',
                  ),
                  _TestStep(
                    number: '3',
                    text:
                        'Or send to a topic (news / offers / alerts) by toggling subscriptions above, then targeting that topic in the console.',
                  ),
                  _TestStep(
                    number: '4',
                    text:
                        'Check the Notification History screen (bell icon) to see received messages.',
                    last: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── History Button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
                icon: const Icon(Icons.history),
                label: const Text('View Notification History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final String topic;
  final String label;
  final IconData icon;
  final Color color;
  final bool subscribed;
  final VoidCallback onToggle;

  const _TopicTile({
    required this.topic,
    required this.label,
    required this.icon,
    required this.color,
    required this.subscribed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: subscribed ? color.withOpacity(0.12) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: subscribed ? color.withOpacity(0.5) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: subscribed ? color : Colors.white38, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: subscribed ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'topic: $topic',
                  style: TextStyle(
                    color: subscribed ? color.withOpacity(0.8) : Colors.white24,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: subscribed,
            onChanged: (_) => onToggle(),
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _TestStep extends StatelessWidget {
  final String number;
  final String text;
  final bool last;
  const _TestStep(
      {required this.number, required this.text, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFF6C63FF).withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
