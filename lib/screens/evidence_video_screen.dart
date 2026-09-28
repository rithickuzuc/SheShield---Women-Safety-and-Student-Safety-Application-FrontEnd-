import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EvidenceVideoScreen extends StatefulWidget {
  const EvidenceVideoScreen({super.key, required this.path, required this.title});
  final String path;
  final String title;
  @override State<EvidenceVideoScreen> createState() => _EvidenceVideoScreenState();
}
class _EvidenceVideoScreenState extends State<EvidenceVideoScreen> {
  late final VideoPlayerController controller;
  late final Future<void> initialized;
  @override void initState() { super.initState(); controller = VideoPlayerController.file(File(widget.path)); initialized = controller.initialize(); }
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Center(child: FutureBuilder<void>(future: initialized, builder: (_, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const CircularProgressIndicator();
      if (snapshot.hasError) return const Text('Unable to open the saved video.');
      return AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller));
    })),
    floatingActionButton: FutureBuilder<void>(future: initialized, builder: (_, snap) => snap.connectionState != ConnectionState.done ? const SizedBox.shrink() : FloatingActionButton(
      onPressed: () { setState(() { controller.value.isPlaying ? controller.pause() : controller.play(); }); },
      child: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
    )),
  );
}
