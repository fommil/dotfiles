;;; local.el --- Local config
;;; Commentary:
;;
;;  Local config and WIP for my laptop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-20"))

(package-ensure-compiled)

(dark-theme)
;;(light-theme)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))

(find-file "~/Projects/haskell-tng.el")
(find-file "~/Projects/haskell-tng.el/haskell-tng-hsinspect.el")

;; flycheck is CPU intensive so only for desktops
;; (add-hook 'haskell-mode-hook
;;           (lambda ()
;;             ;;(setq-local flycheck-checkers '(haskell-ghc haskell-hlint))
;;             (setq-local flycheck-checkers '(haskell-ghc))
;;             (flycheck-mode 1)))

;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:

;;; local.el ends here
