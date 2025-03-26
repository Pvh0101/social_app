import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';

class BetterPlayerSeekBar extends StatefulWidget {
  final BetterPlayerController controller;
  final bool isPlaying;
  final Function() onPause;
  final Function() onPlay;
  final Color backgroundColor;
  final Color progressColor;
  final double height;
  final Color indicatorTextColor;
  final Color indicatorBackgroundColor;

  const BetterPlayerSeekBar({
    Key? key,
    required this.controller,
    required this.isPlaying,
    required this.onPause,
    required this.onPlay,
    this.backgroundColor = Colors.white24,
    this.progressColor = Colors.white,
    this.height = 3.0,
    this.indicatorTextColor = Colors.white,
    this.indicatorBackgroundColor = Colors.black54,
  }) : super(key: key);

  @override
  State<BetterPlayerSeekBar> createState() => _BetterPlayerSeekBarState();
}

class _BetterPlayerSeekBarState extends State<BetterPlayerSeekBar> {
  bool _isDragging = false;
  double _seekPercent = 0.0;

  void _onHorizontalDragStart(DragStartDetails details) {
    Duration? duration =
        widget.controller.videoPlayerController?.value.duration;
    Duration? position =
        widget.controller.videoPlayerController?.value.position;

    if (duration == null || position == null) return;

    setState(() {
      _isDragging = true;
      _seekPercent = position.inMilliseconds / duration.inMilliseconds;
    });
    widget.onPause();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final width = box.size.width;
    setState(() {
      _seekPercent += details.delta.dx / width;
      _seekPercent = _seekPercent.clamp(0.0, 1.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    Duration? duration =
        widget.controller.videoPlayerController?.value.duration;
    if (duration == null) return;

    final position = duration.inMilliseconds * _seekPercent;
    widget.controller.seekTo(Duration(milliseconds: position.round()));
    setState(() {
      _isDragging = false;
    });
    if (widget.isPlaying) {
      widget.onPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: StreamBuilder<dynamic>(
        stream: widget.controller.controllerEventStream,
        builder: (context, snapshot) {
          Duration? duration =
              widget.controller.videoPlayerController?.value.duration;
          Duration? position =
              widget.controller.videoPlayerController?.value.position;

          if (duration == null || position == null) {
            return const SizedBox();
          }

          final progress = _isDragging
              ? _seekPercent
              : position.inMilliseconds / duration.inMilliseconds;

          return Stack(
            children: [
              // Background track
              Container(
                height: widget.height,
                color: widget.backgroundColor,
              ),
              // Progress bar
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: widget.height,
                  color: widget.progressColor,
                ),
              ),
              if (_isDragging)
                // Time indicator
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 10,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.indicatorBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(Duration(
                          milliseconds:
                              (duration.inMilliseconds * _seekPercent).round(),
                        )),
                        style: TextStyle(
                          color: widget.indicatorTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
