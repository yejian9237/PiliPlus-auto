import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:flutter/material.dart';

class CarMiniPlayer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? coverUrl;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const CarMiniPlayer({
    super.key,
    required this.title,
    this.subtitle,
    this.coverUrl,
    required this.position,
    required this.duration,
    this.isPlaying = false,
    this.hasNext = false,
    this.hasPrevious = false,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onTap,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: coverUrl != null
                        ? NetworkImgLayer(
                            src: coverUrl,
                            width: 48,
                            height: 48,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.play_circle_outline,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDuration(position)} / ${_formatDuration(duration)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      hasPrevious ? Icons.skip_previous : Icons.skip_previous_outlined,
                      color: hasPrevious 
                          ? theme.colorScheme.onSurface 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    onPressed: hasPrevious ? onPrevious : null,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: onPlayPause,
                    iconSize: 32,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      hasNext ? Icons.skip_next : Icons.skip_next_outlined,
                      color: hasNext 
                          ? theme.colorScheme.onSurface 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    onPressed: hasNext ? onNext : null,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onClose,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
            ),
          ],
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

class CarVideoControls extends StatelessWidget {
  final PlayerStatus playerStatus;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onRewind;
  final VoidCallback? onFastForward;

  const CarVideoControls({
    super.key,
    required this.playerStatus,
    this.hasNext = false,
    this.hasPrevious = false,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onRewind,
    this.onFastForward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = playerStatus.isPlaying;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.replay_10,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: onRewind,
          iconSize: 40,
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: Icon(
            hasPrevious ? Icons.skip_previous : Icons.skip_previous_outlined,
            color: hasPrevious 
                ? theme.colorScheme.onSurface 
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          onPressed: hasPrevious ? onPrevious : null,
          iconSize: 36,
        ),
        const SizedBox(width: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: onPlayPause,
            iconSize: 40,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(
            hasNext ? Icons.skip_next : Icons.skip_next_outlined,
            color: hasNext 
                ? theme.colorScheme.onSurface 
                : theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          onPressed: hasNext ? onNext : null,
          iconSize: 36,
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: Icon(
            Icons.forward_10,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: onFastForward,
          iconSize: 40,
        ),
      ],
    );
  }
}
