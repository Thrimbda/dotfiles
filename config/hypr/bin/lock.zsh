#!/usr/bin/env zsh
# Lock the current Caelestia session.
#
# SYNOPSIS:
#  lock
#
# DESCRIPTION:
#   Compatibility entrypoint for existing `hey .lock` callers. Legacy styling
#   flags are ignored because Caelestia owns the WlSessionLock surface.

exec caelestia shell lock lock
