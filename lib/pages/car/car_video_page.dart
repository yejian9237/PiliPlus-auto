import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/sponsor_block.dart';
import 'package:PiliPlus/models/common/sponsor_block/segment_model.dart';
import 'package:PiliPlus/models/common/sponsor_block/skip_type.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models_new/sponsor_block/segment_item.dart';
import 'package:PiliPlus/pages/car/widgets/car_mini_player.dart';
import 'package:PiliPlus/pages/car/widgets/car_playlist_widget.dart';
import 'package:PiliPlus/pages/common/full_screen.dart';
import 'package:PiliPlus/pages/common/video_page.dart';
import 'package:PiliPlus/pages/sponsor_block/block_mixin.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/gesture_detector.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/player_build.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/video_render.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/video_widget.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class CarVideoPage extends StatefulWidget {
  final String videoType;
  final String? avid;
  final String? bvid;
  final int? cid;
  final String? p;

  const CarVideoPage({
    super.key,
    required this.videoType,
    this.avid,
    this.bvid,
    this.cid,
    this.p,
  });

  @override
  State<CarVideoPage> createState() => _CarVideoPageState();
}

class _CarVideoPageState extends State<CarVideoPage> with BlockMixin {
  bool _showControls = true;
  bool _showPlaylist = false;
  bool _showDanmaku = true;
  PlPlayerController? _controller;
  final List<SegmentModel> _segmentList = [];
  int? _lastBlockPos;
  bool _isSkippingAd = false;

  @override
  void initState() {
    super.initState();
    _autoHideControls();
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller?.playerStatus.value.isPlaying == true) {
        setState(() {
          _showControls = false;
          _showPlaylist = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _autoHideControls();
      }
    });
  }

  void _togglePlaylist() {
    setState(() {
      _showPlaylist = !_showPlaylist;
      _showControls = _showPlaylist;
    });
  }

  void _toggleDanmaku() {
    setState(() {
      _showDanmaku = !_showDanmaku;
    });
    _controller?.showDanmaku = _showDanmaku;
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
      final result = await querySponsorBlock(bvid, cid);
      if (result != null && mounted) {
        setState(() {
          _segmentList.clear();
          _segmentList.addAll(result);
        });
      }
    } catch (_) {}
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
              icon: Icons.speed,
              title: '播放速度',
              onTap: _showSpeedSheet,
            ),
            _buildSettingsTile(
              icon: _showDanmaku ? Icons.visibility : Icons.visibility_off,
              title: '弹幕',
              subtitle: Text(
                _showDanmaku ? '开启' : '关闭',
                style: const TextStyle(color: Colors.white54),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleDanmaku();
              },
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildVideoPlayer(),
          if (_showControls) _buildTopControls(),
          if (_showControls) _buildBottomControls(),
          if (_showPlaylist) _buildPlaylistPanel(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: VideoWidget(
          avid: widget.avid,
          bvid: widget.bvid,
          cid: widget.cid,
          p: widget.p,
          videoType: widget.videoType,
          onControllerCreated: (controller) {
            _controller = controller;
            _controller!.showDanmaku = _showDanmaku;
            _controller!.addPositionListener(_checkAndSkipAd);
            _controller!.addStatusLister((status) {
              if (status.isPlaying) {
                _initSponsorBlock();
              }
            });
            _updateQueueState();
          },
          onStatusChanged: (status) {
            if (status.isPlaying) {
              _autoHideControls();
            }
            _updateQueueState();
          },
        ),
      ),
    );
  }

  void _updateQueueState() {
    if (_controller != null) {
      _controller!.setQueueState(
        hasNext: _controller!.hasNext,
        hasPrevious: _controller!.hasPrevious,
      );
    }
  }

  Widget _buildTopControls() {
    final theme = Theme.of(context);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => Text(
                    _controller?.videoDetail.value.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  if (_controller != null)
                    Obx(() {
                      final ep = _controller!.episode.value;
                      if (ep != null) {
                        return Text(
                          ep.title ?? '',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                ],
              ),
            ),
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
            IconButton(
              icon: Icon(
                Icons.playlist_play,
                color: _showPlaylist ? theme.colorScheme.primary : Colors.white,
              ),
              onPressed: _togglePlaylist,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final theme = Theme.of(context);
    final isPortrait = MediaQuery.of(context).size.aspectRatio < 1;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final controller = _controller;
              if (controller == null) return const SizedBox.shrink();
              
              return CarVideoControls(
                playerStatus: controller.playerStatus.value,
                hasNext: controller.hasNext,
                hasPrevious: controller.hasPrevious,
                onPlayPause: () {
                  if (controller.playerStatus.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                },
                onNext: controller.hasNext ? () => controller.nextPlay() : null,
                onPrevious: controller.hasPrevious ? () => controller.prevPlay() : null,
                onRewind: () => controller.seekBack(),
                onFastForward: () => controller.seekForward(),
              );
            }),
            if (!isPortrait) const SizedBox(height: 16),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Obx(() {
      final controller = _controller;
      if (controller == null) return const SizedBox.shrink();
      
      final position = controller.position.value;
      final duration = controller.duration.value;
      final buffered = controller.bufferedPosition.value;
      
      final progress = duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;
      final bufferedProgress = duration.inMilliseconds > 0
          ? buffered.inMilliseconds / duration.inMilliseconds
          : 0.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                LinearProgressIndicator(
                  value: bufferedProgress,
                  minHeight: 4,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation(Colors.white54),
                ),
                Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final newPosition = Duration(
                      milliseconds: (value * duration.inMilliseconds).round(),
                    );
                    controller.seek(newPosition);
                  },
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: Colors.white30,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPlaylistPanel() {
    final playlistService = videoPlayerServiceHandler;
    if (playlistService == null) return const SizedBox.shrink();

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.6,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: Colors.black87,
          child: CarPlaylistPanel(
            playlistService: playlistService,
            currentIndex: _controller?.currentIndex ?? 0,
            isPlaying: _controller?.playerStatus.value.isPlaying ?? false,
            onItemTap: (index) {
              playlistService.onSkipToQueueItem?.call(index);
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
