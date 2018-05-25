#!/bin/bash
set -e

export DART_VM_OPTIONS=--preview-dart-2

pub run test -j 1 -r expanded

export DART_VM_OPTIONS=""

if [[ "$TRAVIS_BRANCH" == "master" ]]; then
  pub global activate -sgit https://github.com/stablekernel/codecov_dart.git
  dart_codecov_generator --report-on=lib/ --verbose --no-html
fi
