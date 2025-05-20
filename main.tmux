#!/bin/bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_opt() {
  local option=$1
  local default_value=$2
  local option_value=$(tmux show-option -gqv "$option")
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

set_tmux_opt() {
  local option="$1"
  local value="$2"
  local passed_flags="$3"
  local default_flags="-gq"
  local flags="${default_flags:=passed_flags}"
  tmux set-option "$flags" "$option" "$value"
}

main() {
  # Get Options
  local -A OPT=(
    ["flavour"]="$(get_tmux_opt "@thm_flavour" "onedark")"
    ["style"]="$(get_tmux_opt "@thm_style" 2)"
    ["icons"]="$(get_tmux_opt "@thm_icons" true)"
  )
  # Get Theme
  local -A THM
  while IFS='=' read -r key val; do
    [ "${key##\#*}" ] || continue
    eval "THM[$key]"="$val"
  done <"${PLUGIN_DIR}/themes/${OPT[flavour]}"
  # Set Icons/Separators
  local -A SEP=(
    ["c_l"]=""
    ["c_r"]=""
    ["t_l"]=""
    ["t_r"]=""
    ["b_m"]="│"
    ["b_h"]="▌"
  )
  local -A ICO=(
    ["session"]=" "
    ["command"]=" "
    ["zoomed"]=" "
    ["date"]="󰭦 "
    ["time"]="󰅐 "
  )
  [ ${OPT[icons]} == false ] && ICO=()

  style() {
    local fg bg opts
    fg="$1"
    bg="$2"
    opts="$3"
    echo "#[fg=${THM[$fg]} bg=${THM[$bg]} ${opts}]"
  }

  # Style Default
  local status_left="[#S]"
  local status_right="%H:%M %d-%b-%y"
  local status_window="#I:#W"
  local status_window_current="#[fg=green]#I:#W"
  local status_window_divider=" "

  # Style 1
  if [ "${OPT[style]}" == 1 ]; then
    div="$(style bg2 bg0)${SEP[b_m]}"
    # status-left
    status_left="$(style red bg0 "none italics") ${ICO[session]}#S $div"
    status_left+="$(style green bg0 "italics") ${ICO[command]}#{pane_current_command} "
    status_left+="#{?window_zoomed_flag,$div$(style yellow bg0 "italics") ${ICO[zoomed]}zoomed ,}"
    # status-right
    status_right="$(style cyan bg0 "italics") ${ICO[date]}%Y/%m/%d $div"
    status_right+="$(style blue bg0 "italics") ${ICO[time]}%H:%M "
    # status-window
    status_window="$(style fg2 bg0) #I #[italics]#W "
    status_window_current="$(style magenta bg0) #I #[italics]#W "
    status_window_divider="$div"
  fi

  # Style 2
  if [ "${OPT[style]}" == 2 ]; then
    div="$(style bg0 bg0) "
    # status-left
    status_left="$(style red bg1)${SEP[b_h]}$(style red bg1)${ICO[session]}#S$(style bg1 red)${SEP[b_h]}$div"
    status_left+="$(style green bg1)${SEP[b_h]}$(style green bg1)${ICO[command]}#{pane_current_command}$(style bg1 green)${SEP[b_h]}$div"
    status_left+="#{?window_zoomed_flag,$(style yellow bg1)${SEP[b_h]}$(style yellow bg1)${ICO[zoomed]}zoomed$(style bg1 yellow)${SEP[b_h]},}"
    # status-right
    status_right="$(style cyan bg1)${SEP[b_h]}$(style cyan bg1)${ICO[date]}%Y/%m/%d$(style bg1 cyan)${SEP[b_h]}$div"
    status_right+="$(style blue bg1)${SEP[b_h]}$(style blue bg1)${ICO[time]}%H:%M$(style bg1 blue)${SEP[b_h]}"
    # status-window
    status_window="$(style bg0 fg2)${SEP[b_h]}$(style bg1 fg2)#I#[reverse]${SEP[b_h]}#W$(style bg0 bg1)${SEP[b_h]}"
    status_window_current="$(style bg0 magenta)${SEP[b_h]}$(style bg1 magenta)#I#[reverse]${SEP[b_h]}#W$(style bg0 bg1)${SEP[b_h]}"
    status_window_divider=""
  fi

  # Set Tmux
  set_tmux_opt status-justify "absolute-centre"
  set_tmux_opt status-left-length 200
  set_tmux_opt status-right-length 200
  # General Colors
  set_tmux_opt status-fg "${THM[fg0]}"
  set_tmux_opt status-bg "${THM[bg0]}"
  set_tmux_opt pane-border-style "fg=${THM[bg1]}"
  set_tmux_opt pane-active-border-style "fg=${THM[magenta]}"
  set_tmux_opt message-style "fg=${THM[orange]},bg=${THM[bg0]},bold"
  set_tmux_opt message-command-style "fg=${THM[orange]},bg=${THM[bg0]},bold"
  set_tmux_opt copy-mode-match-style "fg=${THM[bg0]},bg=${THM[yellow]}"
  set_tmux_opt copy-mode-current-match-style "fg=${THM[bg0]},bg=${THM[orange]}"
  set_tmux_opt mode-style "fg=${THM[fg0]},bg=${THM[bg2]}"
  # Status formats
  set_tmux_opt status-left "$status_left"
  set_tmux_opt status-right "$status_right"
  set_tmux_opt window-status-format "$status_window" "-wgq"
  set_tmux_opt window-status-current-format "$status_window_current" "-wgq"
  set_tmux_opt window-status-separator "$status_window_divider" "-wgq"
}

main
