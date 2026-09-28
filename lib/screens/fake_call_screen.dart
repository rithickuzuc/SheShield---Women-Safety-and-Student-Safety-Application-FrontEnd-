import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key, required this.callerName});
  final String callerName;

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _answered = false;
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    try {
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.play(AssetSource('audio/original_iphone.mp3'));
    } catch (_) {
      // The fake call screen must remain usable if device audio is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  Future<void> _answer() async {
    await _ringtonePlayer.stop();
    if (!mounted) return;
    setState(() => _answered = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _closeCall() async {
    await _ringtonePlayer.stop();
    if (mounted) Navigator.of(context).pop();
  }

  String get _duration =>
      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: const Color(0xFF331322),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
          child: Column(
            children: [
              Text(
                _answered ? _duration : 'Incoming call',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const Spacer(),
              const CircleAvatar(
                radius: 58,
                backgroundColor: Color(0xFF8E3A62),
                child: Icon(Icons.person, color: Colors.white, size: 72),
              ),
              const SizedBox(height: 24),
              Text(
                widget.callerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _answered ? 'Connected' : 'Mobile',
                style: const TextStyle(color: Colors.white70, fontSize: 17),
              ),
              const Spacer(),
              if (_answered)
                _CallButton(
                  icon: Icons.call_end,
                  label: 'End',
                  color: Colors.red,
                  onTap: _closeCall,
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CallButton(
                      icon: Icons.call_end,
                      label: 'Decline',
                      color: Colors.red,
                      onTap: _closeCall,
                    ),
                    _CallButton(
                      icon: Icons.call,
                      label: 'Answer',
                      color: Colors.green,
                      onTap: _answer,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final FutureOr<void> Function() onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(72, 72),
        ),
        onPressed: () => onTap(),
        icon: Icon(icon, color: Colors.white, size: 34),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white)),
    ],
  );
}
