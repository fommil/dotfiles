;;; local.el --- Local config
;;; Commentary:
;;
;;  For desktop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-18"))

(package-ensure-compiled)

(require 'sym-humanize)

(when (not window-system)
  (add-to-list 'default-frame-alist
               '(cursor-type . box)))
;; (add-to-list 'default-frame-alist
;;              '(font . "Hack-24"))


(find-file (expand-file-name "scratch.el" user-emacs-directory))

(find-file "~/Work/")

(light-theme)

;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:

;;; local.el ends here
