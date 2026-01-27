MODEL="medium"
rm -f output.wav
ffmpeg -i audio.oga -ar 16000 -ac 1 -c:a pcm_s16le output.wav 2> /dev/null
~/hack/ai/whisper.cpp/main -m ~/hack/ai/whisper.cpp/models/ggml-$MODEL.bin -otxt -f output.wav -l auto 2> /dev/null
