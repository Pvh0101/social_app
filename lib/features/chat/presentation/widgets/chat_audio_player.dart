import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Widget hiển thị và phát audio trong tin nhắn
class ChatAudioPlayer extends ConsumerStatefulWidget {
  final String audioUrl;
  final Color backgroundColor;
  final Color foregroundColor;

  const ChatAudioPlayer({
    Key? key,
    required this.audioUrl,
    required this.backgroundColor,
    required this.foregroundColor,
  }) : super(key: key);

  @override
  ConsumerState<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends ConsumerState<ChatAudioPlayer> {
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
