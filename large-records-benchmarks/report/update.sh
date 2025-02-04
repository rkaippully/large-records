#!/bin/bash

set -e

#
# Run this from the report/ directory.
#
# To benchmark only "coresize", "timing", or "runtime", set the BENCH env var.
# To benchmark only only a specific target, set TARGET.
#
# NOTE: If benchmarking only a single target, you will need to manually remove
# old lines from runtime.csv.
#


## Core size

if [[ "$BENCH" == "" || "$BENCH" == "coresize" ]]
then

  if [[ "$TARGET" == "" || "$TARGET" == "before" ]]; then
    cabal build bench-before --flags=+profile-coresize
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "after" ]]; then
    cabal build bench-after --flags=+profile-coresize
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "experiments" ]]; then
    cabal build bench-experiments --flags=+profile-coresize
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "typelet" ]]; then
    cabal build bench-typelet --flags=+profile-coresize
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "large-anon" ]]; then
    cabal build bench-large-anon --flags=+profile-coresize
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "superrecord" ]]; then
    cabal build bench-superrecord --flags=+profile-coresize
  fi

  cabal run parse-coresize -- \
    --dist ../../dist-newstyle \
    --match '.*/(.*)/Sized/R(.*)\.dump-(ds-preopt|ds|simpl)' \
    -o coresize.csv

fi

## Timing

if [[ "$BENCH" == "" || "$BENCH" == "timing" ]]
then

  if [[ "$TARGET" == "" || "$TARGET" == "before" ]]; then
    cabal build bench-before --flags=+profile-timing
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "after" ]]; then
    cabal build bench-after --flags=+profile-timing
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "experiments" ]]; then
    cabal build bench-experiments --flags=+profile-timing
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "typelet" ]]; then
    cabal build bench-typelet --flags=+profile-timing
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "large-anon" ]]; then
    cabal build bench-large-anon --flags=+profile-timing
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "superrecord" ]]; then
    cabal build bench-superrecord --flags=+profile-timing
  fi

  cabal run parse-timing -- \
    --dist ../../dist-newstyle \
    --match '.*/(.*)/Sized/R(.*)\.dump-timings' \
    --omit-per-phase \
    -o timing.csv

fi

## Runtime

if [[ "$BENCH" == "" || "$BENCH" == "runtime" ]]
then

  if [[ "$TARGET" == "" ]]; then
    rm -f runtime.csv
  fi

  if [[ "$TARGET" == "" || "$TARGET" == "large-anon" ]]; then
    cabal run --flags=+profile-runtime bench-large-anon  -- --csv runtime.csv
  fi
  if [[ "$TARGET" == "" || "$TARGET" == "superrecord" ]]; then
    cabal run --flags=+profile-runtime bench-superrecord -- --csv runtime.csv
  fi

fi

## Plots

gnuplot all-plots.gnuplot
# gnuplot nofieldselectors.gnuplot # from 9.2.1 only
