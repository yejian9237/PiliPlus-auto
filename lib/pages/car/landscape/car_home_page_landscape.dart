import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart';
import 'package:PiliPlus/pages/car/widgets/car_playlist_widget.dart';
import 'package:PiliPlus/pages/car/widgets/car_mini_player.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/view.dart';
import 'package:PiliPlus/route/route.dart';
import 'package:PiliPlus/services/car_playlist_service.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixnum/fixnum.dart' show Int64;

class CarHomePageLandscape extends StatefulWidget {
  const CarHomePageLandscape({super.key});

  @override
  State<CarHomePageLandscape> createState() => _CarHomePageLandscapeState();
}

class _CarHomePageLandscapeState extends State<CarHomePageLandscape> {
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          _buildSidebar(theme),
          VerticalDivider(
            width: 1,
            color: theme.dividerColor,
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(theme),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildVideoGrid(),
                      ),
                      if (_currentPlaylist != null && _currentPlaylist!.isNotEmpty)
                        _buildPlaylistPanel(theme),
                    ],
                  ),
                ),
                if (_currentPlaylist != null && _currentPlaylist!.isNotEmpty)
                  _buildMiniPlayer(),
                if (_currentPlaylist == null || _currentPlaylist!.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 200,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: theme.colorScheme.primary,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PiliPlus',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  label: '首页',
                  isSelected: true,
                  onTap: () {},
                ),
                _buildNavItem(
                  icon: Icons.play_circle_outline,
                  label: '视频',
                  isSelected: false,
                  onTap: () {},
                ),
                _buildNavItem(
                  icon: Icons.music_note,
                  label: '音频',
                  isSelected: false,
                  onTap: () {
                    Get.toNamed('/car/audio');
                  },
                ),
                _buildNavItem(
                  icon: Icons.history,
                  label: '历史',
                  isSelected: false,
                  onTap: () {},
                ),
                _buildNavItem(
                  icon: Icons.favorite_outline,
                  label: '收藏',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    final tabs = ['推荐', 'UP主', '列表', '收藏'];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          ...List.generate(tabs.length, (index) {
            final isSelected = _selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(tabs[index]),
                selected: isSelected,
                onSelected: (_) => _onTabChanged(index),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    if (_isLoading && _currentPlaylist == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentPlaylist == null || _currentPlaylist!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无内容',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 16 / 10,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _currentPlaylist!.length,
      itemBuilder: (context, index) {
        final item = _currentPlaylist![index];
        final arc = item.arc;
        final isCurrent = index == _currentIndex;

        return _buildVideoCard(arc, index, isCurrent);
      },
    );
  }

  Widget _buildVideoCard(dynamic arc, int index, bool isCurrent) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _playItem(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isCurrent 
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
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
                        fontSize: 14,
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
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatCount(arc.cntInfo.play),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
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
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.equalizer,
                          color: theme.colorScheme.onPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '播放中',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 12,
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
  }

  Widget _buildPlaylistPanel(ThemeData theme) {
    if (_currentPlaylist == null || _currentIndex >= _currentPlaylist!.length) {
      return const SizedBox.shrink();
    }

    final item = _currentPlaylist![_currentIndex];
    final arc = item.arc;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
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
                Text(
                  '${_currentIndex + 1}/${_currentPlaylist!.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _currentPlaylist!.length,
              itemBuilder: (context, index) {
                final listItem = _currentPlaylist![index];
                final listArc = listItem.arc;
                final isCurrent = index == _currentIndex;

                return Container(
                  color: isCurrent 
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                      : Colors.transparent,
                  child: ListTile(
                    onTap: () => _playItem(index),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 60,
                        height: 36,
                        child: NetworkImgLayer(
                          src: listArc.cover,
                          width: 60,
                          height: 36,
                        ),
                      ),
                    ),
                    title: Text(
                      listArc.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrent 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _formatCount(listArc.cntInfo.play),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(
                            Icons.equalizer,
                            color: theme.colorScheme.primary,
                            size: 20,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    if (_currentPlaylist == null || _currentIndex >= _currentPlaylist!.length) {
      return const SizedBox.shrink();
    }

    final item = _currentPlaylist![_currentIndex];
    final arc = item.arc;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: CarMiniPlayer(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Text(
          '选择一个视频开始播放',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatCount(Int64 count) {
    if (count >= 100000000) {
      return '${(count ~/ 100000000).toString()}亿播放';
    } else if (count >= 10000) {
      return '${(count ~/ 10000).toString()}万播放';
    }
    return '${count}播放';
  }
}
