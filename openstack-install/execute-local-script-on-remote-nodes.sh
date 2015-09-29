#!/bin/bash

usage() {
  echo "Usage: $0 <script> <node1> <node2> ... [ -- <script-options-args>]"
  echo "<node> can be hostname or ipaddress."
  echo "<script> and <node> MUST NOT contain double hyphen '--'"
  exit
}

[[ $# -lt 2 ]] && usage

SCRIPT=$1

NODES="${@##$1}"
NODES="${NODES%%--*}"

ALL_ARGS=$@
if [[ "$@" != *"--"* ]]; then
SCRIPT_ARGS=""
else
SCRIPT_ARGS="${@##$1}"
SCRIPT_ARGS="${SCRIPT_ARGS#*--}"
fi

for node in $NODES; do
  ssh $node "bash -s" -- < $SCRIPT $SCRIPT_ARGS
done
