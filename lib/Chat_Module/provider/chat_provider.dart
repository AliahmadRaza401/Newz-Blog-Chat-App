import 'dart:async';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  late BuildContext context;

  init({required BuildContext context}) {
    this.context = context;
  }

  bool loading = false;
  final audioPlayer = AudioPlayer();
  late AudioPlayer audioPlayer2;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  late bool _isPlaying;
  late bool _isUploading;
  late bool _isRecorded;
  late bool _isRecording;
  bool play = false;
  double _amplitude = 1;
  int? selectedIndex;

  setselectedIndex(value) {
    selectedIndex = value;
    log('selectedIndex: ${selectedIndex}');
    notifyListeners();
  }

  int time = 0;
  setTime(value) {
    time = value;
    print('time: ${time}');
    notifyListeners();
  }

  Timer? timer;

  countTimer() {
    // if (timer != null) {
    //   timer!.cancel();
    // }
    print("Timer Start");
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print('timer: ${timer}');
      setTime(time++);
    });
  }

  audioplayerInit() {
    audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      s == PlayerState.PLAYING;
      setTime(s);
    });
    audioPlayer.onDurationChanged.listen((Duration s) {
      setDuration(s);
    });
    audioPlayer.onAudioPositionChanged.listen((newPos) {
      setPosition(newPos);
    });

    selectedIndex = -1;
    audioPlayer2 = AudioPlayer();
  }

  setPosition(val) {
    position = val;
    notifyListeners();
  }

  setDuration(val) {
    duration = val;
    notifyListeners();
  }

  setLoading(bool val) {
    loading = val;
    notifyListeners();
  }
}
