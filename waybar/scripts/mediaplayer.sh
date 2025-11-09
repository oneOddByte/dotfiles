#!/bin/bash

player_status=$(playerctl status 2> /dev/null)

if [ "$player_status" = "Playing" ]; then
    artist=$(playerctl metadata artist)
    title=$(playerctl metadata title)
    echo "{\"text\": \"$artist - $title\", \"class\": \"playing\", \"alt\": \"playing\"}"
elif [ "$player_status" = "Paused" ]; then
    artist=$(playerctl metadata artist)
    title=$(playerctl metadata title)
    echo "{\"text\": \"  $artist - $title\", \"class\": \"paused\", \"alt\": \"paused\"}"
else
    echo "{\"text\": \"\", \"class\": \"stopped\", \"alt\": \"stopped\"}"
fi
