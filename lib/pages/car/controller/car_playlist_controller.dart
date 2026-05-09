import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/car/widgets/car_playlist_widget.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/services/car_playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fixnum/fixnum.dart' show Int64;

class CarPlaylistController extends GetxController {
  final CarPlaylistService _playlistService = CarPlaylistService();
  
  final Rx<CarPlaylistType> selectedType = CarPlaylistType.recommend.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  List<DetailItem>? get playlist => _playlistService.currentPlaylist;
  bool get hasNext => _playlistService.hasNext;
  bool get hasPrevious => _playlistService.hasPrevious;

  CarPlaylistService get playlistService => _playlistService;

  @override
  void onInit() {
    super.onInit();
    loadPlaylist();
  }

  Future<void> loadPlaylist() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _playlistService.loadPlaylist(
        source: selectedType.value.source,
        id: Int64(0),
      );

      if (result case Success()) {
        currentIndex.value = _playlistService.currentIndex;
      } else {
        errorMessage.value = '加载播放列表失败';
      }
    } catch (e) {
      errorMessage.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void changeType(CarPlaylistType type) {
    if (selectedType.value != type) {
      selectedType.value = type;
      currentIndex.value = 0;
      loadPlaylist();
    }
  }

  void playItem(int index) {
    if (playlist != null && index >= 0 && index < playlist!.length) {
      _playlistService.setCurrentIndex(index);
      currentIndex.value = index;
      isPlaying.value = true;
    }
  }

  void playNext() {
    if (_playlistService.moveToNext()) {
      currentIndex.value = _playlistService.currentIndex;
    } else if (hasNext) {
      loadMoreNext();
    }
  }

  void playPrevious() {
    if (_playlistService.moveToPrevious()) {
      currentIndex.value = _playlistService.currentIndex;
    }
  }

  Future<void> loadMoreNext() async {
    if (!hasNext || isLoading.value) return;
    
    isLoading.value = true;
    try {
      await _playlistService.loadNextPage();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMorePrevious() async {
    if (!hasPrevious || isLoading.value) return;
    
    isLoading.value = true;
    try {
      await _playlistService.loadPreviousPage();
      currentIndex.value = _playlistService.currentIndex;
    } finally {
      isLoading.value = false;
    }
  }

  void setPlayingState(bool playing) {
    isPlaying.value = playing;
  }

  void clear() {
    _playlistService.clear();
    currentIndex.value = 0;
    isPlaying.value = false;
  }
}

class CarPlaylistPage extends GetView<CarPlaylistController> {
  const CarPlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放列表'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.playlist == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.isNotEmpty && controller.playlist == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadPlaylist,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Obx(() => CarPlaylistTypeSelector(
              selectedType: controller.selectedType.value,
              onTypeChanged: controller.changeType,
            )),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() => CarPlaylistPanel(
                playlistService: controller.playlistService,
                currentIndex: controller.currentIndex.value,
                isPlaying: controller.isPlaying.value,
                onItemTap: controller.playItem,
              )),
            ),
          ],
        );
      }),
    );
  }
}
