// ignore_for_file: avoid_print
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/*
 * getUserMedia sample
 */
class GetUserMediaSample extends StatefulWidget {
  static String tag = 'get_usermedia_sample';

  const GetUserMediaSample({Key? key}) : super(key: key);

  @override
  State<GetUserMediaSample> createState() => _GetUserMediaSampleState();
}

class _GetUserMediaSampleState extends State<GetUserMediaSample> {
  List<MediaStreamTrack>? _tracks;
  final _localRenderer = createVideoRenderer();
  bool _inCalling = false;

  List<MediaDeviceInfo>? _mediaDevicesList;

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_inCalling) {
      _hangUp();
    }
    _localRenderer.dispose();
  }

  void initRenderers() async {
    await _localRenderer.initialize();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void _makeCall() async {
    var caps = DeviceConstraints();
    caps.audio.mandatory = AudioConstraints();
    caps.video.mandatory = DeviceVideoConstraints();
    caps.video.mandatory!.width = 1920;
    caps.video.mandatory!.height = 1080;
    caps.video.mandatory!.fps = 30;

    try {
      var stream = await getUserMedia(caps);
      _mediaDevicesList = await enumerateDevices();
      _tracks = stream;
      await _localRenderer.setSrcObject(
          _tracks!.firstWhere((track) => track.kind() == MediaKind.video));
    } catch (e) {
      print(e.toString());
    }
    if (!mounted) return;

    setState(() {
      _inCalling = true;
    });
  }

  void _hangUp() async {
    try {
      for (var track in _tracks!) {
        await track.stop();
        await track.dispose();
      }
      await _localRenderer.setSrcObject(null);
      setState(() {
        _inCalling = false;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GetUserMedia API Test'),
        actions: _inCalling
            ? <Widget>[
                PopupMenuButton<String>(
                  onSelected: _selectAudioOutput,
                  itemBuilder: (BuildContext context) {
                    if (_mediaDevicesList != null) {
                      return _mediaDevicesList!
                          .where((device) =>
                              device.kind == MediaDeviceKind.audiooutput)
                          .map((device) {
                        return PopupMenuItem<String>(
                          value: device.deviceId,
                          child: Text(device.label),
                        );
                      }).toList();
                    }
                    return [];
                  },
                ),
              ]
            : null,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(color: Colors.black54),
              child: VideoView(_localRenderer, mirror: true),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _inCalling ? _hangUp : _makeCall,
        tooltip: _inCalling ? 'Hangup' : 'Call',
        child: Icon(_inCalling ? Icons.call_end : Icons.phone),
      ),
    );
  }

  void _selectAudioOutput(String deviceId) {
    setOutputAudioId(deviceId);
  }
}
