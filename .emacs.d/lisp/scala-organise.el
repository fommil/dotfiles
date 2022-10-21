;;; scala-organise.el --- organise scala imports -*- lexical-binding: t -*-

;; Copyright (C) 2022 Sam Halliday
;; License: GPL 3 or any later version

;;; Commentary:
;;
;;  A simplistic command that organises Java-style import sections (i.e. no
;;  relative paths). Only the first import section, up to any non-import line
;;  (including comments) is organised. For anything more complex than this,
;;  consider using https://github.com/liancheng/scalafix-organize-imports
;;
;;; Code:

(require 'subr-x)

(defun scala-organise ()
  "Organise the import section"
  (interactive)
  (save-excursion
    (goto-char 0)
    (when (re-search-forward (rx line-start "import "))
      ;; contains a list of imports of the form ("prefix." ("Symbol", "_", "etc"))
      (defvar scala-organise-list nil)
      (forward-line 0)
      (let ((start (point)))
        (while (looking-at (rx (or "\n" (: "import " (group (+ (not (or "{" "\n"))))))))
          (when-let ((match (match-string-no-properties 1)))
            (goto-char (match-end 1))
            (if (looking-at "{")
                ;; multi-part import
                (let ((block-start (point)))
                  (forward-sexp)
                  (let* ((block (buffer-substring-no-properties block-start (point)))
                         (parts (split-string block "," nil (rx (+ (or space "{" "}"))))))
                    (push (list match parts) scala-organise-list)))
              ;; standalone import
              (let* ((part (car (reverse (split-string match (rx ".")))))
                     (prefix (string-remove-suffix part match)))
                (push (list prefix (list part)) scala-organise-list))))
          (forward-line 1))

        ;; TODO group-by the prefix, concat the values
        ;; TODO render back out again in user-defined priority order, then alphabetic
        ;; TODO sort and dedupe the parts, _ wins over *, which wins over everything else
        )

      (message "[scala-organise] %S" scala-organise-list))


    ;; TODO give a reminder when there are untouched inline imports
    ))

(provide 'scala-organise)
;;; scala-organise.el ends here
