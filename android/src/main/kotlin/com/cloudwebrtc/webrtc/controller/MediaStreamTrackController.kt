package com.cloudwebrtc.webrtc.controller

import com.cloudwebrtc.webrtc.proxy.MediaStreamTrackProxy
import com.cloudwebrtc.webrtc.utils.AnyThreadSink
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Controller of [MediaStreamTrackProxy] functional.
 *
 * @property messenger Messenger used for creating new [MethodChannel]s.
 * @property track Underlying [MediaStreamTrackProxy] to perform [MethodCall]s on.
 */
class MediaStreamTrackController(
    private val messenger: BinaryMessenger,
    private val track: MediaStreamTrackProxy
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, IdentifiableController {
  /** Unique ID of the [MethodChannel] of this controller. */
  private val channelId: Long = nextChannelId()

  /** Channel listened for the [MethodCall]s. */
  private val chan: MethodChannel =
      MethodChannel(messenger, ChannelNameGenerator.name("MediaStreamTrack", channelId))

  /** Event channel to send all the [MediaStreamTrackProxy] events into. */
  private val eventChannel: EventChannel =
      EventChannel(messenger, ChannelNameGenerator.name("MediaStreamTrackEvent", channelId))

  /** Event sink ito send all the [MediaStreamTrackProxy] events into. */
  private var eventSink: AnyThreadSink? = null

  /** [MediaStreamTrackProxy] events observer, sending all the events to the [eventSink]. */
  private val eventObserver =
      object : MediaStreamTrackProxy.Companion.EventObserver {
        override fun onEnded() {
          eventSink?.success(mapOf("event" to "onEnded"))
        }
      }

  init {
    chan.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)
    track.addEventObserver(eventObserver)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "setEnabled" -> {
        val enabled: Boolean = call.argument("enabled")!!
        track.setEnabled(enabled)
        result.success(null)
      }
      "state" -> {
        val trackState = track.state()
        result.success(trackState.value)
      }
      "stop" -> {
        track.stop()
        result.success(null)
      }
      "clone" -> {
        result.success(MediaStreamTrackController(messenger, track.fork()).asFlutterResult())
      }
      "dispose" -> {
        chan.setMethodCallHandler(null)
        result.success(null)
      }
    }
  }

  override fun onListen(obj: Any?, sink: EventChannel.EventSink?) {
    if (sink != null) {
      eventSink = AnyThreadSink(sink)
    }
  }

  override fun onCancel(obj: Any?) {
    eventSink = null
  }

  /**
   * Converts this [MediaStreamTrackController] to the Flutter's method call result.
   *
   * @return [Map] generated from this controller which can be returned to the Flutter side.
   */
  fun asFlutterResult(): Map<String, Any> =
      mapOf(
          "channelId" to channelId,
          "id" to track.id(),
          "kind" to track.kind().value,
          "deviceId" to track.deviceId())
}
