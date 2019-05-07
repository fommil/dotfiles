;;; fommil-haskell-tng.el --- Haskell TNG -*- lexical-binding: t -*-

;; Copyright (C) 2019 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  An alternative to haskell-mode that I found on Twitter.
;;
;;  TODO send some PRs to haskell-tng
;;
;;  1. indentation for WLDO almost always gets it wrong. Should be matching on the last inferred ; unless it's the first one, in which case it should be where +2
;;  2. alternative indentation should prioritise the previous line and next line
;;  3. top-levels should be 0 if the previous line is the opener, unless there is a -> or =>
;;  4. GADT definitions are bad, seems to prefer the :: not the entries
;;  5. tag lookup on a FQN.symbol picks up the wrong thing, same with highlight-symbol. @ should be punctuation
;;  6. list indentation, e.g. aligning commas, doesn't work
;;  7. "foo :: Blah <- blah blah" treated as a type signature
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

(bind-key "C-c c" 'haskell-tng-compile haskell-tng-mode-map)
(bind-key "C-c e" 'next-error haskell-tng-mode-map)
(bind-key "C-c c" 'haskell-tng-compile haskell-tng-compilation-mode-map)
(bind-key "C-c e" 'next-error haskell-tng-compilation-mode-map)

(bind-key "C-c C-r f" 'haskell-tng-contrib:stylish-haskell haskell-tng-mode-map)

;; i.e. bypass company-mode
(bind-key "C-<tab>" 'dabbrev-expand haskell-tng-mode-map)

(provide 'fommil-haskell-tng)
;;; fommil-haskell-tng.el ends here
