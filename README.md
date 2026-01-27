# Whisper Bot - Telegram voice transcription bot

This is a Telegram bot that transcribes voice messages using whisper.cpp. You send a voice message, it replies with the text. It's built on top of botlib and follows the same philosophy: simple C code, one thread per request, minimal dependencies.

I wanted voice transcription in Telegram without sending my audio to external services. Whisper.cpp runs locally on my server, and the quality is quite good, much better than the Telegram bots I used so far to do the same task (especially using Whisper medium). The bot handles downloading the audio, converting it to the right format, running whisper, and streaming the result back to Telegram as it's being transcribed.

## How it works

The bot uses botlib's thread-per-request model, but with a twist: since whisper.cpp is CPU/GPU-bound, running multiple instances in parallel makes no sense (in case of a small server, like most users would install this thing on). So threads wait their turn using a mutex. The queue length is tracked with a C11 atomic, and if too many requests pile up, the bot just tells you to try later instead of making everyone wait forever.

There's also a small optimization: when the queue is short, it uses the `medium` model for better quality. When the queue gets longer, it switches to the `base` model to clear the backlog faster. You can tune the threshold. Consider that for languages otehr than English the difference among base and medium is brutal.

The transcription is streamed back to Telegram by editing the message as new text arrives. If the transcription is very long, it automatically continues in a new message (never tested in practice, so far...).

## Dependencies

* libcurl and libsqlite3 (for botlib)
* ffmpeg (for audio conversion)
* whisper.cpp (you need to build it separately)

## Installation

1. Build whisper.cpp and download at least the `base` and `medium` models.

2. Edit `whisperbot.c` and fix the paths at the top:
```c
#define WHISPER_PATH "/path/to/whisper.cpp/main"
#define MODEL_BASE "/path/to/whisper.cpp/models/ggml-base.bin"
#define MODEL_MEDIUM "/path/to/whisper.cpp/models/ggml-medium.bin"
```

3. Create your bot with [@BotFather](https://t.me/botfather) and save the API key in `apikey.txt`.

4. Build and run:
```
make
./whisperbot
```

Use `--verbose` to see what's happening, `--debug` for even more output.

## Configuration

Everything is at the top of `whisperbot.c`:

```c
#define MAX_QUEUE 10            // Max pending requests before rejecting
#define MAX_SECONDS 300         // Max audio duration (5 minutes)
#define MSG_LIMIT 4000          // Telegram message length limit
#define TIMEOUT 600             // Kill whisper after 10 minutes
#define QUEUE_THRESHOLD_BASE 3  // Use base model when queue >= this
#define SHORT_AUDIO_THRESHOLD 1.5  // Seconds, below this use DEFAULT_LANG
#define DEFAULT_LANG "it"       // Language for short audio
```

## Short audio and language detection

Whisper.cpp has trouble with very short audio clips (under ~1.5 seconds): it either fails silently or the auto language detection picks the wrong language. For example, the Italian "Sì ok" gets transcribed as the English "See you K".

To work around this, the bot pads short audio with silence to reach 1.5 seconds, and uses a fixed language (`DEFAULT_LANG`, defaulting to Italian) instead of auto-detection. For longer audio, auto-detection works fine.

If you primarily use a different language, change `DEFAULT_LANG` in the configuration.
Note that even when the message is in English, and we default to the wrong language because of duration, the effect is that the message is often transcribed correctly, but it gets automatically translated.

## Limitations

* The paths to whisper.cpp are hardcoded (edit and recompile).
* No persistence: if you restart the bot, queued requests are lost.
* Short audio uses a fixed language instead of auto-detection (see above, no simple workaround AFAIK).
