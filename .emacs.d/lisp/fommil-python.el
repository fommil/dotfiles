;;; fommil-python.el --- Python Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  Python.
;;
;;; Code:

(require 'company)

;;(use-package elpy)
(use-package python-mode
  :ensure nil
  :bind (("C-c c" . compile)
         ("C-c e" . next-error))
  :hook
  ((python-mode . show-paren-mode)
   (python-mode . electric-pair-local-mode)
   (python-mode . yas-minor-mode)))

;; (add-hook 'python-mode-hook
;;           (lambda ()
;;             (elpy-mode)
;;             (let ((backends (company-backends-for-buffer)))
;;               (setq company-backends (cons 'elpy-company-backend backends)))))
;; (put 'pyvenv-activate 'safe-local-variable #'stringp)

(provide 'fommil-python)

;;; fommil-python.el ends here
