;;; fommil-manuscripts.el --- Manuscript Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  Plain text editing (org-mode, markdown, etc)
;;
;;; Code:

(use-package org
  ;;:pin org
  ;;:ensure org-plus-contrib
  :ensure nil
  :defer t
  :init
  (setq
   org-src-fontify-natively t
   org-export-headline-levels 5)
  :config
  (bind-key "C-c c" 'leanpub-export org-mode-map))

(add-hook 'org-mode-hook
          (lambda ()
            (yas-minor-mode t)
            (company-mode t)
            (visual-line-mode t)
            (local-set-key (kbd "s-c") 'picture-mode)
            (org-babel-do-load-languages
             'org-babel-load-languages
             '((ditaa . t)
               (dot   . t)))))

(use-package markdown-mode
  :commands markdown-mode)
(add-hook 'markdown-mode-hook
          (lambda ()
            (yas-minor-mode t)
            (company-mode t)
            (visual-line-mode t)))

(defun writing-mode-hooks ()
  "Common hooks for writing modes."
  ;;(setq company-backends '(company-yasnippet))
  (flyspell-mode)
  (whitespace-mode-with-local-variables))
;; performance problems in emacs 24.5 (e.g. email)
;;(add-hook 'text-mode-hook #'writing-mode-hooks)
(add-hook 'org-mode-hook #'writing-mode-hooks)
(add-hook 'markdown-mode-hook #'writing-mode-hooks)

(defun markdown-flyspell-predicate ()
  "Refine the default text predicate to ignore markdown specific things."
  (and
   (text-flyspell-predicate)
   (not
    ;; this relies on faces so doesn't work if flyspell-buffer is
    ;; called before faces are available (e.g. in a hook)
    (let ((f (get-text-property (- (point) 1) 'face)))
      (member f '(markdown-pre-face markdown-language-keyword-face))))))
(put #'markdown-mode #'flyspell-mode-predicate #'markdown-flyspell-predicate)

(provide 'fommil-manuscripts)

;;; fommil-manuscripts.el ends here
