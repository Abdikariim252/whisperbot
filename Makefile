CC = cc
CFLAGS = -O2 -Wall -W -std=c11
LDFLAGS = -lcurl -lsqlite3 -lpthread

OBJS = whisperbot.o botlib.o sds.o cJSON.o json_wrap.o sqlite_wrap.o

all: whisperbot

whisperbot: $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $<

whisperbot.o: whisperbot.c botlib.h sds.h
botlib.o: botlib.c botlib.h sds.h cJSON.h sqlite_wrap.h
sds.o: sds.c sds.h sdsalloc.h
cJSON.o: cJSON.c cJSON.h
json_wrap.o: json_wrap.c cJSON.h
sqlite_wrap.o: sqlite_wrap.c sqlite_wrap.h

clean:
	rm -f whisperbot $(OBJS)

.PHONY: all clean
