;;; fommil-haskell-tng.el --- Haskell TNG -*- lexical-binding: t -*-

;; Copyright (C) 2019 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  An alternative to haskell-mode that I found on Twitter.
;;
;;; Code:

(require 'smartparens)
;; WORKAROUND smartparens is indenting all the time, which is not good
(defun sp--indent-region (_1 _2 &optional _3)
  ;; disable this function
  )

;; (defun sp--indent-region (start end &optional column)
;;   "Call `indent-region' unless `aggressive-indent-mode' is enabled.

;; START, END and COLUMN are the same as in `indent-region'."
;;   (unless (bound-and-true-p aggressive-indent-mode)
;;     ;; Don't issue "Indenting region..." message.
;;     (cl-letf (((symbol-function 'message) #'ignore))
;;       (indent-region start end column))))


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

(bind-key "RET" 'comment-indent-new-line haskell-tng-mode-map)

(bind-key "C-M-<return>" 'haskell-tng-smie:debug-newline haskell-tng-mode-map)
(bind-key "C-M-<tab>" 'haskell-tng-smie:debug-tab haskell-tng-mode-map)

(bind-key "C-c C" 'stack2cabal haskell-tng-mode-map)
(bind-key "C-c c" 'haskell-tng-compile haskell-tng-mode-map)
(bind-key "C-c e" 'next-error haskell-tng-mode-map)
(bind-key "C-c c" 'haskell-tng-compile haskell-tng-compilation-mode-map)
(bind-key "C-c e" 'next-error haskell-tng-compilation-mode-map)

(bind-key "C-c C-r f" 'haskell-tng-contrib:stylish-haskell haskell-tng-mode-map)

;; i.e. bypass company-mode
(bind-key "C-<tab>" 'dabbrev-expand haskell-tng-mode-map)

;; quick hack to jump to imports. Would be better to manage without visiting,
;; and at the very least a way to pop back to where we were.
(bind-key "C-c n i"
          (lambda ()
            (interactive)
            (re-search-backward (rx line-start "import")))
          haskell-tng-mode-map)

(provide 'fommil-haskell-tng)
;;; fommil-haskell-tng.el ends here
