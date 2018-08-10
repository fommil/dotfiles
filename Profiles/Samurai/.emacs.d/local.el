;;; local.el --- Local config
;;; Commentary:
;;
;;  For desktop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-14"))

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))

(let ((day (string-to-number (format-time-string "%u")))
      (hour (string-to-number (format-time-string "%H"))))
 (if (and (< day 6) (< hour 18) (> hour 8))
     (find-file "~/Work")
   (find-file "~/Projects")))

(let ((hour (string-to-number (format-time-string "%H"))))
  (if (< hour 20)
      (light-theme)
    (dark-theme)))

;;; local.el ends here
