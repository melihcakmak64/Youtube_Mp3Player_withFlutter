import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:music_player/controller/DownloadController.dart';
import 'package:music_player/helper/helper.dart';

class MusicSlider extends StatelessWidget {
  MusicSlider({super.key, required this.controller});
  DownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.sliderShown.value
        ? Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(20)),
              height: 70,
              margin: EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(formatDuration(controller.currentPosition.value)),
                    Expanded(
                      child: Slider(
                        value: controller.currentPosition.value.inSeconds
                            .toDouble(),
                        max:
                            controller.totalDuration.value.inSeconds.toDouble(),
                        onChanged: (value) {
                          controller.player
                              .seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Text(formatDuration(controller.totalDuration.value)),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink());
  }
}
