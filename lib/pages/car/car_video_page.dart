import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/gesture_detector.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/player_build.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/video_render.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/video_widget.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/pages/car/widgets/car_mini_player.dart';
import 'package:PiliPlus/pages/car/widgets/car_playlist_widget.dart';
import 'package:PiliPlus/pages/common/common_video_page.dart';
import 'package:PiliPlus/pages/common/full_screen.dart';
import 'package:PiliPlus/pages/common/video_page.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
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

class _CarVideoPageState extends State<CarVideoPage> {
  bool _showControls = true;
  bool _showPlaylist = false;
  PlPlayerController? _controller;

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
