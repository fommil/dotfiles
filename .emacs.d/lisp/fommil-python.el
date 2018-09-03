;;; fommil-python.el --- Python Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  Python.
;;
;;; Code:

(use-package elpy)
(use-package python-mode
  :ensure nil
  :bind ("C-c e" . next-error))

(add-hook 'python-mode-hook
          (lambda ()
            (smartparens-mode)
            (elpy-mode)
            (let ((backends (company-backends-for-buffer)))
              (setq company-backends (cons 'elpy-company-backend backends)))))
(put 'pyvenv-activate 'safe-local-variable #'stringp)

(provide 'fommil-python)

;;; fommil-python.el ends here
