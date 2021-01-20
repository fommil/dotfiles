;;; scala-compile.el --- batch compile scala -*- lexical-binding: t -*-

;; Copyright (C) 2020 Sam Halliday
;; License: GPL 3 or any later version

;;; Commentary:
;;
;;  An idiomatic `compilation-mode' batch compilation command that detects
;;  warnings and errors, extracting line numbers, columns and ranges.
;;
;;  Relies on a batch tool, such as the sbt thin client (`sbt --client`) which
;;  can be compiled to native binary (`sbtn`) from their repo with `sbt
;;  buildNativeThinClient` or mystery meat binaries downloaded from
;;  https://github.com/sbt/sbtn-dist/releases/
;;
;;; Code:

(require 'compile)
(require 'ansi-color)
(require 'files)
(require 'subr-x)

;; TODO flycheck integration https://emacs.stackexchange.com/questions/51894
;; TODO is -Dsbt.supershell=false needed?

(defcustom scala-compile-always-ask t
  "`scala-compile' will remember the last command for the buffer unless set."
  :type 'booleanp
  :group 'scala)

(defcustom scala-compile-suggestion nil
  "Files can specify a suggested command to run, e.g. runMain and testOnly."
  :type 'stringp
  :group 'scala
  :safe 'stringp
  :local t)

(defvar scala-compilation-error-regexp-alist
  '(;; Sbt 1.0.x
    ("^\\[error][[:space:]]\\([/[:word:]]:?[^:[:space:]]+\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\):" 1 2 3 2 1)
    ;; Sbt 0.13.x
    ("^\\[error][[:space:]]\\([/[:word:]]:?[^:[:space:]]+\\):\\([[:digit:]]+\\):" 1 2 nil 2 1)
    ;; https://github.com/Duhemm/sbt-errors-summary
    ("^\\[error][[:space:]]\\[E[[:digit:]]+][[:space:]]\\([/[:word:]]:?[^:[:space:]]+\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\):$" 1 2 3 2 1)
    ("^\\[warn][[:space:]]+\\[E[[:digit:]]+][[:space:]]\\([/[:word:]]:?[^:[:space:]]+\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\):$" 1 2 3 1 1)
    ("^\\[warn][[:space:]]\\([/[:word:]]:?[^:[:space:]]+\\):\\([[:digit:]]+\\):" 1 2 nil 1 1)
    ("^\\[info][[:space:]]\\([/[:word:]]:?[^:[:space:]]+\\):\\([[:digit:]]+\\):" 1 2 nil 0 1)
    ;; failing scalatests
    ("^\\[info][[:space:]]+\\(.*\\) (\\([^:[:space:]]+\\):\\([[:digit:]]+\\))" 2 3 nil 2 1)
    ("^\\[warn][[:space:]][[:space:]]\\[[[:digit:]]+][[:space:]]\\([/[:word:]]:?[^:[:space:]]+\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\):" 1 2 3 1 1)
    )
  "The `compilation-error-regexp-alist' for `scala'.")

(defvar scala--compile-history
  '("sbtn compile"
    "sbtn test"
    "sbtn testOnly "))

(defvar-local scala--compile-command nil)
(defvar-local scala--compile-alt "sbtn clean")
(defvar scala--compile-project "build.sbt")

;;;###autoload
(defun scala-compile (&optional edit-command)
  "`compile' specialised to Scala.

First use in a buffer or calling with a prefix will prompt for a
command, otherwise the last command is used.

The command history is global.

A universal argument will invoke `scala--compile-alt', which
will cause the subsequent call to prompt."
  (interactive "P")
  (save-some-buffers (not compilation-ask-about-save)
                     compilation-save-buffers-predicate)

  (when scala-compile-suggestion
    (add-to-list 'scala--compile-history scala-compile-suggestion))

  (let* ((last scala--compile-command)
         (command (pcase edit-command
                    ((and 'nil (guard last)) last)
                    ('-  scala--compile-alt)
                    (_ (read-shell-command
                        "Compile command: "
                        (or last (car scala--compile-history))
                        '(scala--compile-history . 1))))))
    (setq scala--compile-command
          (unless (or
                   scala-compile-always-ask
                   (equal command scala--compile-alt))
            command))
    (let ((default-directory
            (or
             (locate-dominating-file default-directory scala--compile-project)
             default-directory)))
      (compilation-start
       command
       'scala-compilation-mode
       ;; TODO name the compilation buffer
       ))))

(defun scala--compile-ansi-color ()
  (ansi-color-apply-on-region compilation-filter-start (point-max)))

(define-compilation-mode scala-compilation-mode "scala-compilation"
  (add-hook 'compilation-filter-hook
            #'scala--compile-ansi-color nil t))

(provide 'scala-compile)
;;; scala-compile.el ends here
