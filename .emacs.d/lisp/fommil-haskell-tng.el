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
  (require 'haskell-tng-contrib)
  (require 'haskell-tng-contrib-company)
  (require 'haskell-tng-contrib-projectile)
  (require 'haskell-tng-contrib-smartparens)
  (require 'haskell-tng-contrib-yasnippet)

  :bind
  (:map
   haskell-tng-compilation-mode-map
   (("C-c c" . haskell-tng-compile)
    ("C-c e" . next-error)))
  (:map
   haskell-tng-mode-map
   ("C-<tab>" . dabbrev-expand)

   ("RET" . haskell-tng-newline)
   ("C-c c" . haskell-tng-compile)
   ("C-c e" . next-error)

   ("C-M-RET" . haskell-tng--smie-debug-newline)
   ("C-M-<tab>" . haskell-tng--smie-debug-tab)

   ("C-c C-n i" . haskell-tng-goto-imports)
   ("C-c C-n m" . haskell-tng-current-module)

   ("C-c C-i s" . haskell-tng-fqn-at-point)

   ("C-c C" . haskell-tng-stack2cabal)
   ("C-c C-r f" . haskell-tng-stylish-haskell)))

(add-hook
 'haskell-tng-mode-hook
 (lambda ()
   (whitespace-mode-with-local-variables)
   (show-paren-mode 1)
   (git-gutter-mode 1)))

(provide 'fommil-haskell-tng)
;;; fommil-haskell-tng.el ends here
