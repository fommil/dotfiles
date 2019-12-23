;;; local.el --- Local config
;;; Commentary:
;;
;;  Local config and WIP for my laptop.
;;
;;; Code:

(require 'use-package)

(use-package darcula-theme)

(setq ensime-server-version "2.0.0-graph-SNAPSHOT")

(add-to-list 'default-frame-alist
             '(font . "Hack-18"))

(defun dark-theme ()
  "A dark coloured theme for hacking when there is no screen glare."
  (interactive)
  (load-theme 'darcula t))
(dark-theme)

(defun light-theme ()
  "A light coloured theme for hacking when there is lots of screen glare."
  (interactive)
  (load-theme 'leuven t))

(find-file (expand-file-name "scratch.el" user-emacs-directory))

;; I'll usually want access to these..
(find-file "~/Projects/")


;;; local.el ends here
