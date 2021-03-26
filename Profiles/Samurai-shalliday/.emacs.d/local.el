;;; local.el --- Local config
;;; Commentary:
;;
;;  For desktop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-28"))

(package-ensure-compiled)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))

;;(light-theme)
(dark-theme)

;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:

;;; local.el ends here
