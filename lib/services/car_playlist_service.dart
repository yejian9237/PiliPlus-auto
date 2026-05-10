import 'package:PiliPlus/grpc/audio.dart';
import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:fixnum/fixnum.dart' show Int64;

class CarPlaylistService {
  static final CarPlaylistService _instance = CarPlaylistService._internal();
  factory CarPlaylistService() => _instance;
  CarPlaylistService._internal();

  List<DetailItem>? _currentPlaylist;
  int _currentIndex = 0;
  PlaylistSource? _currentSource;
  Int64? _currentId;
  String? _nextCursor;
  String? _prevCursor;

  List<DetailItem>? get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get hasNext => _nextCursor != null;
  bool get hasPrevious => _prevCursor != null;

  Future<LoadingState<PlaylistResp>> loadPlaylist({
    required PlaylistSource source,
    required Int64 id,
    Int64? oid,
    List<Int64>? subId,
    int? itemType,
    Int64? extraId,
    ListOrder order = ListOrder.ORDER_NORMAL,
  }) async {
    _currentSource = source;
    _currentId = id;
    
    final result = await AudioGrpc.audioPlayList(
      source: source,
      id: id,
      oid: oid,
      subId: subId,
      itemType: itemType,
      extraId: extraId,
      order: order,
    );

    if (result case Success(:final response)) {
      _currentPlaylist = response.list;
      _nextCursor = response.paginationReply?.next;
      _prevCursor = response.paginationReply?.prev;
      
      if (oid != null) {
        final idx = _currentPlaylist?.indexWhere((e) => e.item.oid == oid) ?? -1;
        if (idx != -1) {
          _currentIndex = idx;
        }
      }
    }

    return result;
  }

  Future<LoadingState<PlaylistResp>> loadNextPage() async {
    if (_currentSource == null || _currentId == null || _nextCursor == null) {
      return const Error('No more pages');
    }

    final result = await AudioGrpc.audioPlayList(
      source: _currentSource!,
      id: _currentId!,
      next: _nextCursor,
    );

    if (result case Success(:final response)) {
      _currentPlaylist?.addAll(response.list);
      _nextCursor = response.paginationReply?.next;
    }

    return result;
  }

  Future<LoadingState<PlaylistResp>> loadPreviousPage() async {
    if (_currentSource == null || _currentId == null || _prevCursor == null) {
      return const Error('No previous pages');
    }

    final result = await AudioGrpc.audioPlayList(
      source: _currentSource!,
      id: _currentId!,
      next: _prevCursor,
    );

    if (result case Success(:final response)) {
      _currentPlaylist?.insertAll(0, response.list);
      _prevCursor = response.paginationReply?.prev;
    }

    return result;
  }

  void setCurrentIndex(int index) {
    if (_currentPlaylist != null && index >= 0 && index < _currentPlaylist!.length) {
      _currentIndex = index;
    }
  }

  DetailItem? getCurrentItem() {
    if (_currentPlaylist == null || _currentIndex < 0 || _currentIndex >= _currentPlaylist!.length) {
      return null;
    }
    return _currentPlaylist![_currentIndex];
  }

  DetailItem? getNextItem() {
    if (_currentPlaylist == null || _currentIndex + 1 >= _currentPlaylist!.length) {
      return null;
    }
    return _currentPlaylist![_currentIndex + 1];
  }

  DetailItem? getPreviousItem() {
    if (_currentPlaylist == null || _currentIndex - 1 < 0) {
      return null;
    }
    return _currentPlaylist![_currentIndex - 1];
  }

  bool moveToNext() {
    if (hasNext) {
      if (_currentIndex + 1 < _currentPlaylist!.length) {
        _currentIndex++;
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  bool moveToPrevious() {
    if (_currentIndex - 1 >= 0) {
      _currentIndex--;
      return true;
    }
    return false;
  }

  void clear() {
    _currentPlaylist = null;
    _currentIndex = 0;
    _currentSource = null;
    _currentId = null;
    _nextCursor = null;
    _prevCursor = null;
  }
}

enum CarPlaylistType {
  recommend('推荐', PlaylistSource.DEFAULT),
  upArchive('UP主投稿', PlaylistSource.UP_ARCHIVE),
  mediaList('播放列表', PlaylistSource.MEDIA_LIST),
  userFav('用户收藏', PlaylistSource.USER_FAVOURITE),
  audioCollection('音频合集', PlaylistSource.AUDIO_COLLECTION),
  memSpace('空间内容', PlaylistSource.MEM_SPACE);

  final String label;
  final PlaylistSource source;
  const CarPlaylistType(this.label, this.source);
}
