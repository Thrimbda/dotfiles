#!/usr/bin/env janet
# TODO
#
# SYNOPSIS:
#   sync [...]
#   sync --rollback [GENERATION]

(use hey)
(use hey/cmd)
(use sh)

(defcmd sync [_ cmd & args &opts fast? --fast]
  (when (= (flake :host) "nixos")
    (abort "HOST is 'nixos'. Did you forget to change it?"))

  (unless (empty? (hey swap --list))
    (abort "There are swapped files among your dotfiles!"))

  (os/setenv "HEYENV" (flake/json))
  (log "HEYENV=%s" (os/getenv "HEYENV"))
  (ensure-heyenv!)

  (var target-os (or (flake/host-meta :os) "nixos"))
  (log "Target host %s detected as %s" (flake :host) target-os)

  (case* cmd
    "rollback"
    (if (empty? args)
      (array/push args "--rollback" "switch")
      (do (do? $? sudo nix-env
               --switch-generation ,(in args 0)
               --profile ,(path :profile))
          (break)))
    ["check" "ch"]
    (do? $? nix flake check --impure
         --no-warn-dirty
         --no-use-registries
         --no-write-lock-file
         --no-update-lock-file
         ,(path :home))
    (do? $? sudo --preserve-env=HEYENV
         ,(if (= target-os "darwin") "darwin-rebuild" "nixos-rebuild")
         --show-trace
         --impure
         --flake ,(string (path :home) "#" (flake :host))
         ,;(if (= target-os "nixos") (opts fast?) [])
         ,;(opts (or cmd "switch"))
         ,;args)))
