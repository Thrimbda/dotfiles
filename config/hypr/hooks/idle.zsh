#!/usr/bin/env zsh
# React to various idle states.
#
# SYNOPSIS:
#   idle [--on|--off] [dpms|lock|sleep]
#
# SYNOPSIS:
#   Triggered when there's a change in idle state by the session idle driver.

case $2 in
  '')
    case $1 in
      --on)
        sleep 0.2
        if (( $+commands[brightnessctl] )); then
          brightnessctl -m -s set 10
        else
          # A poor man's screen dimmer
          hey set hypr.hook.last-shader "$(hyprshade current)"
          hyprshade on screen-dim
        fi
        ;;
      --off)
        if (( $+commands[brightnessctl] )); then
          brightnessctl -m -r
        else
          local sh="$(hey get hypr.hook.last-shader)"
          if [[ -n "$sh" ]]; then
            hyprshade on "$sh"
          else
            hyprshade off
          fi
        fi
        ;;
    esac
    ;;

  dpms)
    sleep 0.2
    case $1 in
      --on)
        hyprctl dispatch dpms off
        ;;
      --off)
        hyprctl dispatch dpms on
        ;;
    esac
    ;;

  lock)
    case $1 in
      --on) ;;
      --off) ;;
    esac
    ;;

  sleep)
    case $1 in
      --on)
        playerctl -a pause &
        hey .play-sound shutdown
        {
          hey .lock
          sleep 1
          hey .play-sound startup
        } &
        sleep 3
      ;;
      --off)
        {
          hyprctl dispatch dpms on
        } &
        ;;
    esac
    ;;
esac
