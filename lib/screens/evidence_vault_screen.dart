import 'package:flutter/material.dart';
import 'package:sheshield/models/evidence_record.dart';
import 'package:sheshield/services/evidence_vault_service.dart';
import 'package:sheshield/screens/evidence_video_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class EvidenceVaultScreen extends StatefulWidget { const EvidenceVaultScreen({super.key}); @override State<EvidenceVaultScreen> createState() => _EvidenceVaultScreenState(); }
class _EvidenceVaultScreenState extends State<EvidenceVaultScreen> {
  final service = EvidenceVaultService(); late Future<List<EvidenceRecord>> future;
  @override void initState() { super.initState(); future = service.list(); }
  void refresh() { final next = service.list(); setState(() { future = next; }); }
  @override void dispose() { service.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Evidence Vault')), body: FutureBuilder<List<EvidenceRecord>>(future: future, builder: (context, snap) {
    if (!snap.hasData) return const Center(child: CircularProgressIndicator()); final records = snap.data!; if (records.isEmpty) return const Center(child: Text('Evidence will appear here after SOS activation.'));
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: records.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) => _EvidenceCard(record: records[i], service: service, onChanged: refresh));
  }));
}
class _EvidenceCard extends StatefulWidget { const _EvidenceCard({required this.record, required this.service, required this.onChanged}); final EvidenceRecord record; final EvidenceVaultService service; final VoidCallback onChanged; @override State<_EvidenceCard> createState() => _EvidenceCardState(); }
class _EvidenceCardState extends State<_EvidenceCard> { bool recording = false, busy = false;
  final AudioPlayer player = AudioPlayer();
  bool playing = false;
  @override void dispose() { player.dispose(); super.dispose(); }
  Future<void> audio() async { try { if (recording) { await widget.service.stopAudio(widget.record); } else { await widget.service.startAudio(widget.record); } setState(() => recording = !recording); widget.onChanged(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } }
  Future<void> video() async { setState(() => busy = true); try { await widget.service.captureVideo(widget.record); widget.onChanged(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } finally { if (mounted) setState(() => busy = false); } }
  Future<void> playAudio() async {
    final path = widget.record.audioPath; if (path == null) return;
    if (playing) { await player.stop(); if (mounted) setState(() => playing = false); return; }
    await player.play(DeviceFileSource(path));
    if (mounted) setState(() => playing = true);
    player.onPlayerComplete.first.then((_) { if (mounted) setState(() => playing = false); });
  }
  Future<void> viewVideo() async { final path = widget.record.videoPath; if (path == null) return; await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => EvidenceVideoScreen(path: path, title: widget.record.id))); }
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.record.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Date & time: ${widget.record.createdAt.toLocal()}'), Text('GPS: ${widget.record.latitude}, ${widget.record.longitude}'), Text('Audio: ${widget.record.audioPath == null ? 'Not captured' : 'Available'}'), Text('Video: ${widget.record.videoPath == null ? 'Not captured' : 'Available'}'), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [FilledButton.tonalIcon(onPressed: audio, icon: Icon(recording ? Icons.stop : Icons.mic), label: Text(recording ? 'Stop Audio' : 'Record Audio')), OutlinedButton.icon(onPressed: busy ? null : video, icon: const Icon(Icons.videocam), label: const Text('Record Video')), if (widget.record.audioPath != null) OutlinedButton.icon(onPressed: playAudio, icon: Icon(playing ? Icons.stop_circle : Icons.play_circle), label: Text(playing ? 'Stop Audio' : 'Play Audio')), if (widget.record.videoPath != null) OutlinedButton.icon(onPressed: viewVideo, icon: const Icon(Icons.play_circle_fill), label: const Text('View Video'))])])));
}
