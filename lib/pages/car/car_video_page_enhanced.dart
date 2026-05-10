import 'dart:async';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/sponsor_block.dart';
import 'package:PiliPlus/models/common/sponsor_block/segment_model.dart';
import 'package:PiliPlus/models/common/sponsor_block/skip_type.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models_new/sponsor_block/segment_item.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/widgets/header_control.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/view/view.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class CarVideoPageEnhanced extends StatefulWidget {
  final String videoType;
  final String? avid;
  final String? bvid;
  final int? cid;
  final String? p;

  const CarVideoPageEnhanced({
    super.key,
    required this.videoType,
    this.avid,
    this.bvid,
    this.cid,
    this.p,
  });

  @override
  State<CarVideoPageEnhanced> createState() => _CarVideoPageEnhancedState();
}

class _CarVideoPageEnhancedState extends State<CarVideoPageEnhanced> {
  bool _showDanmaku = true;
  bool _isLoading = true;
  late VideoDetailController _videoDetailController;
  final List<SegmentModel> _segmentList = [];
  int? _lastBlockPos;
  bool _isSkippingAd = false;

  @override
  void initState() {
    super.initState();
    _initVideoController();
  }

  void _initVideoController() {
    _videoDetailController = Get.put(VideoDetailController());

    if (widget.bvid != null) {
      _videoDetailController.initVideo(
        widget.videoType,
        widget.bvid!,
        widget.cid,
        widget.p,
      );
    } else if (widget.avid != null) {
      _videoDetailController.initVideo(
        widget.videoType,
        widget.avid!,
        widget.cid,
        widget.p,
      );
    }

    // 等待播放器初始化完成
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _setupBlockListener();
      }
    });
  }

  PlPlayerController? get _controller => _videoDetailController.plPlayerController;

  void _setupBlockListener() {
    _controller?.addPositionListener(_checkAndSkipAd);
    _controller?.addStatusLister((status) {
      if (status.isPlaying) {
        _initSponsorBlock();
      }
    });
  }

  void _checkAndSkipAd(Duration position) {
    if (!Pref.enableSponsorBlock) return;
    if (_segmentList.isEmpty) return;

    int currentPos = position.inSeconds;
    if (currentPos == _lastBlockPos) return;
    _lastBlockPos = currentPos;

    final msPos = currentPos * 1000;
    for (final item in _segmentList) {
      if (msPos <= item.segment.$1 && item.segment.$1 <= msPos + 1000) {
        switch (item.skipType) {
          case SkipType.alwaysSkip:
          case SkipType.skipOnce:
            if (!_isSkippingAd) {
              _isSkippingAd = true;
              _skipToEndOfSegment(item);
            }
            break;
          case SkipType.skipManually:
            _showSkipPrompt(item);
            break;
          default:
            break;
        }
        break;
      }
    }
  }

  void _skipToEndOfSegment(SegmentModel item) async {
    if (_controller == null) return;
    final targetPos = Duration(milliseconds: item.segment.$2);
    await _controller!.seekTo(targetPos);
    _isSkippingAd = false;
    if (Pref.blockToast) {
      SmartDialog.showToast('已跳过${item.segmentType.shortTitle}片段');
    }
  }

  void _showSkipPrompt(SegmentModel item) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          '检测到${item.segmentType.title}',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '${DurationUtils.formatDuration(item.segment.$1 / 1000)} - ${DurationUtils.formatDuration(item.segment.$2 / 1000)}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _skipToEndOfSegment(item);
            },
            child: const Text('跳过'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _initSponsorBlock() async {
    if (_controller == null) return;
    final bvid = _controller!.bvid;
    final cid = _controller!.cid;
    if (bvid.isEmpty || cid == null) return;
    if (_segmentList.isNotEmpty) return;

    try {
      final result = await _querySponsorBlock(bvid, cid);
      if (result != null && mounted) {
        setState(() {
          _segmentList.clear();
          _segmentList.addAll(result);
        });
      }
    } catch (_) {}
  }

  Future<List<SegmentModel>?> _querySponsorBlock(String bvid, int cid) async {
    final result = await SponsorBlock.getSkipSegments(bvid: bvid, cid: cid);
    switch (result) {
      case Success<List<SegmentItemModel>>(:final response):
        return _convertToSegmentModels(response);
      default:
        return null;
    }
  }

  List<SegmentModel> _convertToSegmentModels(List<SegmentItemModel> items) {
    final blockSettings = Pref.blockSettings;
    final enableList = blockSettings
        .where((item) => item.second != SkipType.disable)
        .map((item) => item.first.name)
        .toSet();

    return items
        .where((item) =>
            enableList.contains(item.category) &&
            item.segment[1] >= item.segment[0])
        .map((item) => SegmentModel.fromItemModel(item, null))
        .toList();
  }

  void _toggleDanmaku() {
    setState(() {
      _showDanmaku = !_showDanmaku;
    });
    _controller?.showDanmaku = _showDanmaku;
  }

  void _showQualitySheet() {
    if (_controller == null) return;
    final videoInfo = _videoDetailController.data;
    if (videoInfo.dash == null || videoInfo.supportFormats == null) {
      SmartDialog.showToast('暂无画质可选');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '选择画质',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...videoInfo.supportFormats!.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final currentQa = _videoDetailController.currentVideoQa.value;
              final isSelected = currentQa?.code == item.quality;
              return ListTile(
                title: Text(
                  item.newDesc ?? '',
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.white,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  if (currentQa?.code == item.quality) return;
                  final quality = item.quality!;
                  final newQa = VideoQuality.fromCode(quality);
                  _videoDetailController
                    ..plPlayerController.cacheVideoQa = newQa.code
                    ..currentVideoQa.value = newQa
                    ..updatePlayer();
                  SmartDialog.showToast('画质已变为：${newQa.desc}');
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSubtitleSheet() {
    if (_controller == null) return;
    if (_videoDetailController.subtitles.isEmpty) {
      SmartDialog.showToast('暂无字幕');
      return;
    }

    final currentIndex = _videoDetailController.vttSubtitlesIndex.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '字幕',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                '关闭字幕',
                style: TextStyle(color: Colors.white),
              ),
              trailing: currentIndex == 0
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                _videoDetailController.setSubtitle(0);
                Navigator.pop(context);
              },
            ),
            ..._videoDetailController.subtitles.asMap().entries.map((entry) {
              final index = entry.key;
              final subtitle = entry.value;
              final isSelected = currentIndex == index + 1;
              return ListTile(
                title: Text(
                  '${subtitle.lanDoc}',
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.white,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  _videoDetailController.setSubtitle(index + 1);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              icon: Icons.high_quality,
              title: '画质',
              onTap: _showQualitySheet,
            ),
            _buildSettingsTile(
              icon: Icons.speed,
              title: '播放速度',
              onTap: _showSpeedSheet,
            ),
            _buildSettingsTile(
              icon: Icons.closed_caption,
              title: '字幕',
              onTap: _showSubtitleSheet,
            ),
            _buildSettingsTile(
              icon: _showDanmaku ? Icons.visibility : Icons.visibility_off,
              title: '弹幕',
              subtitle: Text(
                _showDanmaku ? '开启' : '关闭',
                style: const TextStyle(color: Colors.white54),
              ),
              onTap: _toggleDanmaku,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }

  void _showSpeedSheet() {
    if (_controller == null) return;
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              '播放速度',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...speeds.map((speed) => ListTile(
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: _controller?.playbackSpeed == speed
                          ? Colors.blue
                          : Colors.white,
                    ),
                  ),
                  trailing: _controller?.playbackSpeed == speed
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    _controller?.setPlaybackSpeed(speed);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<VideoDetailController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                '加载中...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _videoDetailController.videoTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDanmaku ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: _toggleDanmaku,
            tooltip: '弹幕开关',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsSheet,
            tooltip: '设置',
          ),
        ],
      ),
      body: PLVideoPlayer(
        maxWidth: size.width,
        maxHeight: size.height,
        plPlayerController: _videoDetailController.plPlayerController,
        videoDetailController: _videoDetailController,
        introController: _videoDetailController,
        headerControl: HeaderControl(
          isPortrait: true,
          controller: _videoDetailController.plPlayerController,
          videoDetailCtr: _videoDetailController,
        ),
        heroTag: 'car_video_player_${widget.bvid}',
      ),
    );
  }
}
