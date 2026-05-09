import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/pages/car/widgets/car_mini_player.dart';
import 'package:PiliPlus/pages/car/widgets/car_playlist_widget.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/view.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/widgets/video_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CarVideoPageLandscape extends StatefulWidget {
  final String videoType;
  final String? avid;
  final String? bvid;
  final int? cid;
  final String? p;

  const CarVideoPageLandscape({
    super.key,
    required this.videoType,
    this.avid,
    this.bvid,
    this.cid,
    this.p,
  });

  @override
  State<CarVideoPageLandscape> createState() => _CarVideoPageLandscapeState();
}

class _CarVideoPageLandscapeState extends State<CarVideoPageLandscape> {
  bool _showControls = true;
  bool _showPlaylist = false;
  PlPlayerController? _controller;
  bool _showDescription = false;

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
    });
  }

  void _toggleDescription() {
    setState(() {
      _showDescription = !_showDescription;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildVideoPlayer(),
              ),
              if (_showPlaylist) _buildPlaylistPanel(),
            ],
          ),
          if (_showControls) _buildOverlayControls(),
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

  Widget _buildOverlayControls() {
    return Stack(
      children: [
        _buildTopBar(),
        _buildCenterControls(),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildTopBar() {
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => Text(
                    _controller?.videoDetail.value.title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(height: 4),
                  Obx(() {
                    final ep = _controller!.episode.value;
                    if (ep != null) {
                      return Text(
                        ep.title ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: _showDescription ? Colors.white : Colors.white70,
              ),
              onPressed: _toggleDescription,
            ),
            IconButton(
              icon: Icon(
                _showPlaylist ? Icons.playlist_add_check : Icons.playlist_add,
                color: _showPlaylist ? Colors.white : Colors.white70,
              ),
              onPressed: _togglePlaylist,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: Obx(() {
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
    );
  }

  Widget _buildBottomControls() {
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
            _buildProgressBar(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  final controller = _controller;
                  if (controller == null) return const SizedBox.shrink();

                  final position = controller.position.value;
                  final duration = controller.duration.value;

                  return Text(
                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  );
                }),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: () {
                        // 全屏逻辑
                      },
                    ),
                  ],
                ),
              ],
            ),
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
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              LinearProgressIndicator(
                value: bufferedProgress,
                minHeight: 4,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white54),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    final newPosition = Duration(
                      milliseconds: (value * duration.inMilliseconds).round(),
                    );
                    controller.seek(newPosition);
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.transparent,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPlaylistPanel() {
    final theme = Theme.of(context);
    final playlistService = videoPlayerServiceHandler;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '播放列表',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _togglePlaylist,
                ),
              ],
            ),
          ),
          Expanded(
            child: playlistService != null
                ? CarPlaylistPanel(
                    playlistService: playlistService,
                    currentIndex: _controller?.currentIndex ?? 0,
                    isPlaying: _controller?.playerStatus.value.isPlaying ?? false,
                    onItemTap: (index) {
                      playlistService.onSkipToQueueItem?.call(index);
                    },
                  )
                : const Center(
                    child: Text('暂无播放列表'),
                  ),
          ),
        ],
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
