import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/audio/controller.dart';
import 'package:PiliPlus/pages/car/controller/car_playlist_controller.dart';
import 'package:PiliPlus/pages/car/widgets/car_playlist_widget.dart';
import 'package:PiliPlus/services/car_playlist_service.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixnum/fixnum.dart' show Int64;

class CarAudioPage extends StatefulWidget {
  const CarAudioPage({super.key});

  @override
  State<CarAudioPage> createState() => _CarAudioPageState();
}

class _CarAudioPageState extends State<CarAudioPage> {
  CarPlaylistService _playlistService = CarPlaylistService();
  List<DetailItem>? _currentPlaylist;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  CarPlaylistType _selectedType = CarPlaylistType.audioCollection;
  bool _showPlaylist = false;

  AudioController? _audioController;

  @override
  void initState() {
    super.initState();
    _initAudioController();
    _loadPlaylist(_selectedType);
  }

  void _initAudioController() {
    if (Get.isRegistered<AudioController>()) {
      _audioController = Get.find<AudioController>();
    }
  }

  Future<void> _loadPlaylist(CarPlaylistType type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _playlistService.loadPlaylist(
        source: type.source,
        id: Int64(0),
      );

      if (result case Success(:final response)) {
        setState(() {
          _currentPlaylist = response.list;
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTypeChanged(CarPlaylistType type) {
    if (_selectedType != type) {
      setState(() {
        _selectedType = type;
        _currentIndex = 0;
      });
      _loadPlaylist(type);
    }
  }

  void _playItem(int index) {
    if (_currentPlaylist != null && index >= 0 && index < _currentPlaylist!.length) {
      setState(() {
        _currentIndex = index;
        _isPlaying = true;
      });

      final item = _currentPlaylist![index];
      final arc = item.arc;

      if (_audioController != null) {
        _audioController!.playAudio(
          avid: arc.aid.toInt(),
          bvid: arc.bvid,
          title: arc.title,
          coverUrl: arc.cover,
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_audioController != null) {
      if (_isPlaying) {
        _audioController!.pause();
      } else {
        _audioController!.play();
      }
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      _playItem(_currentIndex - 1);
    }
  }

  void _playNext() {
    if (_currentPlaylist != null && _currentIndex < _currentPlaylist!.length - 1) {
      _playItem(_currentIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildNowPlaying(),
                const SizedBox(height: 32),
                _buildProgressBar(),
                const SizedBox(height: 24),
                _buildControls(),
                const SizedBox(height: 24),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildPlaylist(),
                ),
              ],
            ),
          ),
          if (_showPlaylist) _buildPlaylistPanel(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_currentPlaylist == null || _currentIndex >= _currentPlaylist!.length) {
      return Container(color: Colors.black);
    }

    final item = _currentPlaylist![_currentIndex];
    return Stack(
      fit: StackFit.expand,
      children: [
        NetworkImgLayer(
          src: item.arc.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Container(
          color: Colors.black.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          const Spacer(),
          Text(
            '音频模式 FM',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _showPlaylist ? Icons.queue_music : Icons.queue_music_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showPlaylist = !_showPlaylist;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    final theme = Theme.of(context);

    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.music_note,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '暂无播放内容',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    final item = _currentPlaylist![_currentIndex];
    final arc = item.arc;

    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NetworkImgLayer(
              src: arc.cover,
              width: 220,
              height: 220,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          arc.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          item.owner.isNotEmpty 
              ? item.owner.map((e) => e.name).join(', ')
              : '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Obx(() {
      if (_audioController == null) return const SizedBox.shrink();

      final position = _audioController!.position.value;
      final duration = _audioController!.duration.value;
      
      final progress = duration.inMilliseconds > 0
          ? position.inMilliseconds / duration.inMilliseconds
          : 0.0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * duration.inMilliseconds).round(),
                  );
                  _audioController?.seek(newPosition);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
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
            ),
          ],
        ),
      );
    });
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.skip_previous,
            color: _currentIndex > 0 ? Colors.white : Colors.white30,
            size: 40,
          ),
          onPressed: _currentIndex > 0 ? _playPrevious : null,
        ),
        const SizedBox(width: 16),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 40,
            ),
            onPressed: _togglePlayPause,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            Icons.skip_next,
            color: _currentPlaylist != null && _currentIndex < _currentPlaylist!.length - 1 
                ? Colors.white 
                : Colors.white30,
            size: 40,
          ),
          onPressed: _currentPlaylist != null && _currentIndex < _currentPlaylist!.length - 1 
              ? _playNext 
              : null,
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return CarPlaylistTypeSelector(
      selectedType: _selectedType,
      onTypeChanged: _onTypeChanged,
    );
  }

  Widget _buildPlaylist() {
    if (_isLoading && _currentPlaylist == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无音频内容',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white30,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _currentPlaylist!.length,
      itemBuilder: (context, index) {
        final item = _currentPlaylist![index];
        final isCurrent = index == _currentIndex;

        return CarPlaylistItem(
          item: item,
          isPlaying: _isPlaying && isCurrent,
          isCurrent: isCurrent,
          onTap: () => _playItem(index),
        );
      },
    );
  }

  Widget _buildPlaylistPanel() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.7,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          color: Colors.black87,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '播放列表',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showPlaylist = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildPlaylist(),
              ),
            ],
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
