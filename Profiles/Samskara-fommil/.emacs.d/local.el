;;; local.el --- Local config
;;; Commentary:
;;
;;  For desktop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-14"))

(use-package darcula-theme)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))
(find-file "~/Projects")

;; beta tester
(setq ensime-server-version "2.0.0-graph-SNAPSHOT")

;;; local.el ends here
