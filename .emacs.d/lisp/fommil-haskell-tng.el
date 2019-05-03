;;; fommil-haskell-tng.el --- Haskell TNG -*- lexical-binding: t -*-

;; Copyright (C) 2019 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  An alternative to haskell-mode that I found on Twitter.
;;
;;  TODO send some PRs to haskell-tng
;;
;;  1. indentation for WLDO almost always gets it wrong
;;  2. alternative indentation should prioritise the previous line and next line
;;
;;; Code:

(add-to-load-path "~/Projects/haskell-tng.el")
(require 'haskell-tng-mode)
(require 'haskell-tng-contrib)

(add-hook
 'haskell-tng-mode-hook
 (lambda ()
   (whitespace-mode-with-local-variables)
   (show-paren-mode 1)
   (smartparens-mode 1)
   (yas-minor-mode 1)
   (git-gutter-mode 1)
   (company-mode 1)
   (prettify-symbols-mode 1)

   (setq company-backends (company-backends-for-buffer))))

(bind-key "C-c c" 'haskell-compile haskell-tng-mode-map)
(bind-key "C-c e" 'next-error haskell-tng-mode-map)
(bind-key "C-c c" 'haskell-compile haskell-tng-compilation-mode-map)
(bind-key "C-c e" 'next-error haskell-tng-compilation-mode-map)

(bind-key "C-c C-r f" 'haskell-tng-contrib:stylish-haskell haskell-tng-mode-map)

;; i.e. bypass company-mode
(bind-key "C-<tab>" 'dabbrev-expand haskell-tng-mode-map)

(provide 'fommil-haskell-tng)
;;; fommil-haskell-tng.el ends here
