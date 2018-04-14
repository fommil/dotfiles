;;; local.el --- Local config
;;; Commentary:
;;
;;  For desktop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-16"))

;; (use-package lsp-mode)
;; (add-to-load-path (expand-file-name "~/Projects/lsp-scala/"))
;; (require 'lsp-scala)
;; (setq lsp-scala-server-command '("metals" "0.1.0-M1+75-905bf282"))

;;(dark-theme)
(light-theme)

(setq compilation-skip-threshold 2)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))
;;(find-file "~/Projects/scalaz/core/src/main/scala/scalaz")
;;(find-file "~/Projects/fpmortals/manuscript/book.org")
(find-file "~/Work")
;;(switch-to-buffer "*scratch*")

;;(setq org-ditaa-jar-path (expand-file-name "~/.ditaa.jar"))

;; e.g. dir-locals.el
;;((nil . ((pyvenv-activate . "/home/fommil/Projects/PROJ/.env")
;;         (compile-command . "./py scratch.py"))))

;;; local.el ends here
