;;; fommil-python.el --- Python Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  Python.
;;
;;; Code:

(use-package python
  :ensure nil
  :config
  :bind
  (:map python-mode-map
        ("M-<delete>" . paredit-unwrap)
        ("C-c c" . compile)
        ("C-c e" . next-error))
  :hook
  ((python-mode . show-paren-mode)
   (python-mode . electric-pair-local-mode)
   (python-mode . yas-minor-mode)
   (python-mode . company-mode)))

(add-hook 'python-mode-hook
          (lambda ()
            (eglot-ensure)))
;; (put 'pyvenv-activate 'safe-local-variable #'stringp)

(provide 'fommil-python)

;;; fommil-python.el ends here
