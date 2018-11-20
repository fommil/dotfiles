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
   (find-file "~/Projects/ghc-prof-flamegraph/ghc-prof-flamegraph.hs")
   (find-file "~/Projects/haskell-tng.el/haskell-tng-font-lock.el")
   (find-file "~/.emacs.d/scratch.el")))

;;(find-file "~/Projects/scalaz72")
;;(find-file "~/Projects/fpmortals/example/")
;;(find-file "~/Projects/fpmortals/manuscript/book.org")

(when window-system
  (let ((hour (string-to-number (format-time-string "%H"))))
    (if (and (< 8 hour) (< hour 20))
        (light-theme)
      (dark-theme))))

;;; local.el ends here
