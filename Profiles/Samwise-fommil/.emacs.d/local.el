;;; local.el --- Local config
;;; Commentary:
;;
;;  Local config and WIP for my laptop.
;;
;;; Code:

(add-to-list 'default-frame-alist
             '(font . "Hack-28"))

(package-ensure-compiled)

(dark-theme)
;;(light-theme)

;; I'll usually want access to these..
(find-file (expand-file-name "scratch.el" user-emacs-directory))

(notmuch)

(defun personal-gptel-settings ()
  (interactive)
  ;; 0.6b is just for testing, it's useless
  ;; ollama pull qwen3:0.6b
  ;; 3.6 27b really needs a GPU
  ;; ollama pull qwen3.6:27b
  ;; ollama pull qwen3:8b
  (let ((models '(qwen3:8b qwen3.6:27b qwen3:0.6b)))
   (setq
    gptel-model (car models)
    gptel-backend (gptel-make-ollama "qwen"
                    :host "localhost:11434"
                    :stream t
                    :models models))))
;;(personal-gptel-settings)

;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:

;;; local.el ends here
