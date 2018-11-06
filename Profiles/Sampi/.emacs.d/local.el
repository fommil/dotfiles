;;; local.el --- Local config
;;; Commentary:
;;
;;  Local config and WIP for my laptop.
;;
;;; Code:

(require 'use-package)

;;(setq ensime-server-version "2.0.0-graph-SNAPSHOT")

(add-to-list 'default-frame-alist
             '(font . "Hack-16"))

;; (bind-key "C-c c" 'sbt-hydra:hydra sbt:mode-map)
;; (bind-key "C-c c" 'sbt-hydra:hydra java-mode-map)
;; (bind-key "C-c c" 'sbt-hydra:hydra dired-mode-map)

;;(dark-theme)
(light-theme)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))

;;; local.el ends here
