import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart';
import 'package:PiliPlus/pages/car/widgets/car_playlist_widget.dart';
import 'package:PiliPlus/pages/car/widgets/car_mini_player.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/view.dart';
import 'package:PiliPlus/route/route.dart';
import 'package:PiliPlus/services/car_playlist_service.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixnum/fixnum.dart' show Int64;

class CarHomePage extends StatefulWidget {
  const CarHomePage({super.key});

  @override
  State<CarHomePage> createState() => _CarHomePageState();
}

class _CarHomePageState extends State<CarHomePage> {
  int _selectedIndex = 0;
  CarPlaylistService _playlistService = CarPlaylistService();
  List<DetailItem>? _currentPlaylist;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylist(CarPlaylistType.recommend);
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

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        _loadPlaylist(CarPlaylistType.recommend);
        break;
      case 1:
        _loadPlaylist(CarPlaylistType.upArchive);
        break;
      case 2:
        _loadPlaylist(CarPlaylistType.mediaList);
        break;
      case 3:
        _loadPlaylist(CarPlaylistType.userFav);
        break;
    }
  }

  void _playItem(int index) {
    if (_currentPlaylist != null && index >= 0 && index < _currentPlaylist!.length) {
      final item = _currentPlaylist![index];
      final arc = item.arc;
      
      setState(() {
        _currentIndex = index;
        _isPlaying = true;
      });

      Get.toNamed(Routes.videoDetail, arguments: {
        'bvid': arc.bvid,
        'avid': arc.aid,
        'cid': arc.cid,
        'title': arc.title,
        'videoType': VideoType.ugc,
      });
    }
  }

  void _togglePlayPause() {
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
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildContent(),
            ),
            if (_currentPlaylist != null && _currentPlaylist!.isNotEmpty)
              _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.directions_car,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            'PiliPlus 车机版',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              Get.toNamed('/audio');
            },
            tooltip: '音频模式',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final tabs = ['推荐', 'UP主', '列表', '收藏'];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(index),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected 
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _currentPlaylist == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无内容',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadPlaylist(CarPlaylistType.values[_selectedIndex]);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 16 / 9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _currentPlaylist!.length,
        itemBuilder: (context, index) {
          final item = _currentPlaylist![index];
          final arc = item.arc;
          final isCurrent = index == _currentIndex;

          return GestureDetector(
            onTap: () => _playItem(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isCurrent 
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImgLayer(
                      src: arc.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            arc.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatCount(arc.cntInfo.play),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent && _isPlaying)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.equalizer,
                                color: theme.colorScheme.onPrimary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '播放中',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayer() {
    if (_currentPlaylist == null || _currentIndex >= _currentPlaylist!.length) {
      return const SizedBox.shrink();
    }

    final item = _currentPlaylist![_currentIndex];
    final arc = item.arc;

    return CarMiniPlayer(
      title: arc.title,
      subtitle: item.owner.isNotEmpty 
          ? item.owner.map((e) => e.name).join(', ')
          : '',
      coverUrl: arc.cover,
      position: Duration.zero,
      duration: Duration(seconds: arc.duration.toInt()),
      isPlaying: _isPlaying,
      hasNext: _currentIndex < _currentPlaylist!.length - 1,
      hasPrevious: _currentIndex > 0,
      onPlayPause: _togglePlayPause,
      onNext: _playNext,
      onPrevious: _playPrevious,
      onTap: () {
        Get.toNamed(Routes.videoDetail, arguments: {
          'bvid': arc.bvid,
          'avid': arc.aid,
          'cid': arc.cid,
          'title': arc.title,
          'videoType': VideoType.ugc,
        });
      },
      onClose: () {
        setState(() {
          _currentPlaylist = null;
          _currentIndex = 0;
          _isPlaying = false;
        });
      },
    );
  }

  String _formatCount(Int64 count) {
    if (count >= 100000000) {
      return '${(count ~/ 100000000).toString()}亿';
    } else if (count >= 10000) {
      return '${(count ~/ 10000).toString()}万';
    }
    return count.toString();
  }
}
