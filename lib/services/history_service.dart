import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:fixnum/fixnum.dart' show Int64;

class HistoryService extends GetxService {
  static const String _boxName = 'car_history';
  static const String _historyKey = 'history_items';
  static const int _maxHistoryItems = 50;

  late Box<List<dynamic>> _box;
  final RxList<HistoryItem> historyList = <HistoryItem>[].obs;

  Future<HistoryService> init() async {
    _box = await Hive.openBox<List<dynamic>>(_boxName);
    _loadHistory();
    return this;
  }

  void _loadHistory() {
    final data = _box.get(_historyKey);
    if (data != null) {
      try {
        final items = data.cast<Map<dynamic, dynamic>>().map((e) {
          return HistoryItem.fromJson(Map<String, dynamic>.from(e));
        }).toList();
        historyList.assignAll(items);
      } catch (e) {
        historyList.clear();
      }
    }
  }

  Future<void> _saveHistory() async {
    final data = historyList.map((e) => e.toJson()).toList();
    await _box.put(_historyKey, data);
  }

  Future<void> addToHistory({
    required Int64 avid,
    String? bvid,
    required String title,
    String? coverUrl,
    required Int64 progress,
    required Int64 duration,
    int? cid,
    int? epid,
    String? upName,
  }) async {
    final existingIndex = historyList.indexWhere(
      (item) => item.avid == avid && item.bvid == bvid,
    );

    final newItem = HistoryItem(
      avid: avid,
      bvid: bvid ?? '',
      title: title,
      coverUrl: coverUrl ?? '',
      progress: progress,
      duration: duration,
      cid: cid ?? 0,
      epid: epid ?? 0,
      upName: upName ?? '',
      lastPlayedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (existingIndex != -1) {
      historyList.removeAt(existingIndex);
    }

    historyList.insert(0, newItem);

    if (historyList.length > _maxHistoryItems) {
      historyList.removeLast();
    }

    await _saveHistory();
  }

  Future<void> updateProgress({
    required Int64 avid,
    String? bvid,
    required Int64 progress,
  }) async {
    final index = historyList.indexWhere(
      (item) => item.avid == avid && item.bvid == bvid,
    );

    if (index != -1) {
      final item = historyList[index];
      historyList[index] = HistoryItem(
        avid: item.avid,
        bvid: item.bvid,
        title: item.title,
        coverUrl: item.coverUrl,
        progress: progress,
        duration: item.duration,
        cid: item.cid,
        epid: item.epid,
        upName: item.upName,
        lastPlayedAt: DateTime.now().millisecondsSinceEpoch,
      );

      historyList.removeAt(index);
      historyList.insert(0, historyList.removeAt(index));

      await _saveHistory();
    }
  }

  Future<void> removeFromHistory(Int64 avid, {String? bvid}) async {
    historyList.removeWhere(
      (item) => item.avid == avid && item.bvid == bvid,
    );
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    historyList.clear();
    await _box.delete(_historyKey);
  }

  List<HistoryItem> getContinuePlayList() {
    return historyList
        .where((item) {
          final progressPercent = item.duration > 0
              ? item.progress / item.duration
              : 0.0;
          return progressPercent < 0.95;
        })
        .take(20)
        .toList();
  }

  HistoryItem? getLastPlayed() {
    if (historyList.isEmpty) return null;
    return historyList.first;
  }
}

class HistoryItem {
  final Int64 avid;
  final String bvid;
  final String title;
  final String coverUrl;
  final Int64 progress;
  final Int64 duration;
  final int cid;
  final int epid;
  final String upName;
  final int lastPlayedAt;

  HistoryItem({
    required this.avid,
    required this.bvid,
    required this.title,
    required this.coverUrl,
    required this.progress,
    required this.duration,
    required this.cid,
    required this.epid,
    required this.upName,
    required this.lastPlayedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      avid: Int64(json['avid'] ?? 0),
      bvid: json['bvid'] ?? '',
      title: json['title'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      progress: Int64(json['progress'] ?? 0),
      duration: Int64(json['duration'] ?? 0),
      cid: json['cid'] ?? 0,
      epid: json['epid'] ?? 0,
      upName: json['upName'] ?? '',
      lastPlayedAt: json['lastPlayedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avid': avid.toInt(),
      'bvid': bvid,
      'title': title,
      'coverUrl': coverUrl,
      'progress': progress.toInt(),
      'duration': duration.toInt(),
      'cid': cid,
      'epid': epid,
      'upName': upName,
      'lastPlayedAt': lastPlayedAt,
    };
  }

  double get progressPercent {
    if (duration <= 0) return 0.0;
    return (progress / duration).clamp(0.0, 1.0);
  }

  Duration get progressDuration => Duration(milliseconds: progress.toInt());
  Duration get totalDuration => Duration(milliseconds: duration.toInt());

  String get progressText {
    final p = progressDuration;
    final d = totalDuration;
    final pMin = p.inMinutes;
    final pSec = p.inSeconds % 60;
    final dMin = d.inMinutes;
    final dSec = d.inSeconds % 60;
    return '${pMin.toString().padLeft(2, '0')}:${pSec.toString().padLeft(2, '0')} / ${dMin.toString().padLeft(2, '0')}:${dSec.toString().padLeft(2, '0')}';
  }
}
