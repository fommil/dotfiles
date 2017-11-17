;;; local.el --- Local config
;;; Commentary:
;;
;;  For desktop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-14"))

(light-theme)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))
;;(find-file "~/Projects/fpmortals/manuscript/book.org")
;;(find-file "~/Work")

(setq org-ditaa-jar-path (expand-file-name "~/.ditaa.jar"))

;; e.g. dir-locals.el
;;((nil . ((pyvenv-activate . "/home/fommil/Projects/PROJ/.env")
;;         (compile-command . "./py scratch.py"))))

;;; local.el ends here
