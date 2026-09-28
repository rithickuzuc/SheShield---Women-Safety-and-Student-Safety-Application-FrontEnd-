import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sheshield/models/evidence_record.dart';

class EvidenceVaultService {
  final AudioRecorder _recorder = AudioRecorder();
  Future<Directory> _directory() async { final root = await getApplicationDocumentsDirectory(); final dir = Directory('${root.path}/evidence_vault'); if (!await dir.exists()) await dir.create(recursive: true); return dir; }
  Future<File> _index() async => File('${(await _directory()).path}/evidence.json');
  Future<List<EvidenceRecord>> list() async { final file = await _index(); if (!await file.exists()) return []; final data = jsonDecode(await file.readAsString()) as List; return data.map((e) => EvidenceRecord.fromJson(e as Map<String, dynamic>)).toList(); }
  Future<void> _save(List<EvidenceRecord> records) async => (await _index()).writeAsString(jsonEncode(records.map((e) => e.toJson()).toList()), flush: true);
  Future<EvidenceRecord> create({required int emergencyId, required double latitude, required double longitude}) async { final records = await list(); final record = EvidenceRecord(id: 'EV${emergencyId.toString().padLeft(4, '0')}', emergencyId: emergencyId, createdAt: DateTime.now(), latitude: latitude, longitude: longitude); records.insert(0, record); await _save(records); return record; }
  Future<void> startAudio(EvidenceRecord evidence) async { if (!await _recorder.hasPermission()) throw Exception('Microphone permission was denied.'); final path = '${(await _directory()).path}/${evidence.id}.m4a'; await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path); }
  Future<EvidenceRecord> stopAudio(EvidenceRecord evidence) async { final path = await _recorder.stop(); if (path == null) throw Exception('Audio recording could not be saved.'); return update(evidence.copyWith(audioPath: path)); }
  Future<EvidenceRecord> captureVideo(EvidenceRecord evidence) async { final picked = await ImagePicker().pickVideo(source: ImageSource.camera, maxDuration: const Duration(minutes: 3)); if (picked == null) return evidence; final target = File('${(await _directory()).path}/${evidence.id}.mp4'); await File(picked.path).copy(target.path); return update(evidence.copyWith(videoPath: target.path)); }
  Future<EvidenceRecord> update(EvidenceRecord evidence) async {
    final records = await list();
    final index = records.indexWhere((e) => e.id == evidence.id);
    if (index >= 0) {
      records[index] = evidence;
    } else {
      records.insert(0, evidence);
    }
    await _save(records);
    return evidence;
  }
  Future<bool> isRecording() => _recorder.isRecording();
  void dispose() => _recorder.dispose();
}
