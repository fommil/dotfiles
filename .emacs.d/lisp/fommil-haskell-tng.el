;;; fommil-haskell-tng.el --- Haskell TNG -*- lexical-binding: t -*-

;; Copyright (C) 2019 Sam Halliday
;; License: http://www.gnu.org/licenses/gpl-3.0.en.html

;;; Commentary:
;;
;;  An alternative to haskell-mode that I found on Twitter.
;;
;;; Code:

(require 'company)
(require 'rx)
(require 'smartparens)

(use-package haskell-tng-mode
  :ensure nil
  :load-path "~/Projects/haskell-tng.el"
  :mode ((rx ".hs" eos) . haskell-tng-mode)

  :config
  (require 'haskell-tng-hsinspect)
  (require 'haskell-tng-extra)
  (require 'haskell-tng-extra-abbrev)
  (require 'haskell-tng-extra-company)
  (require 'haskell-tng-extra-projectile)
  (require 'haskell-tng-extra-smartparens)
  (require 'haskell-tng-extra-yasnippet)

  ;; TODO this abbrev doesn't work
  (define-abbrev
    haskell-tng-mode-abbrev-table
    "???" "panic \"TODO not implemented\"")
  (define-abbrev
    haskell-tng-mode-abbrev-table
    "panic" "panic \"TODO not implemented\"")

  :bind
  (:map
   haskell-tng-compilation-mode-map
   ("C-c c" . haskell-tng-compile)
   ("C-c e" . next-error))
  (:map
   haskell-tng-mode-map
   ("C-<tab>" . dabbrev-expand)

   ("RET" . haskell-tng-newline)

   ;; building
   ("C-c c" . haskell-tng-compile)
   ("C-c e" . next-error)
   ("C-c C" . haskell-tng-stack2cabal)

   ;; debugging
   ("C-M-<return>" . haskell-tng--smie-debug-newline)
   ("C-M-<tab>" . haskell-tng--smie-debug-tab)

   ;; navigation
   ("C-c C-n i" . haskell-tng-goto-imports)
   ("C-c C-n m" . haskell-tng-current-module)

   ;; hsinspect
   ("C-c C-i s" . haskell-tng-fqn-at-point)
   ("C-c C-i i" . haskell-tng-import-symbol-at-point)

   ;; refactoring
   ("C-c C-r f" . haskell-tng-format)
   ("C-c C-r I" . haskell-tng-import-module)
   ;; can't make up my mind...
   ("C-c C-r i" . haskell-tng-import-symbol-at-point)
   ))

(add-hook
 'haskell-tng-mode-hook
 (lambda ()
   (whitespace-mode-with-local-variables)
   (show-paren-mode 1)
   (git-gutter-mode 1)))

(provide 'fommil-haskell-tng)
;;; fommil-haskell-tng.el ends here
