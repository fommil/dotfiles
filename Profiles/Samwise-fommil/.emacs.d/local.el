;;; local.el --- Local config
;;; Commentary:
;;
;;  Local config and WIP for my laptop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-18"))

(package-ensure-compiled)

(dark-theme)
;;(light-theme)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))

(notmuch)

;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:

;;; local.el ends here
