;;; fommil-scala.el --- Scala Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  Support for the Scala language and ecosystem.
;;
;;; Code:

;; Java / Scala support for templates
(defun mvn-package-for-buffer ()
  "Calculate the expected package name for the buffer;
assuming it is in a maven-style project."
  ;; see https://github.com/fommil/dotfiles/issues/66
  (let* ((kind (file-name-extension buffer-file-name))
         (root (locate-dominating-file default-directory kind)))
    (when root
      (require 'subr-x) ;; maybe we should just use 's
      (let ((calculated (replace-regexp-in-string
                         (regexp-quote "/") "."
                         (string-remove-suffix "/"
                                               (string-remove-prefix
                                                (expand-file-name (concat root "/" kind "/"))
                                                default-directory))
                         nil 'literal)))
        (unless (or (null calculated)
                    (string= "" calculated)
                    (s-starts-with-p "." calculated))
          calculated)))))

(defun scala-mode-newline-comments ()
  "Custom newline appropriate for `scala-mode'."
  ;; shouldn't this be in a post-insert hook?
  (interactive)
  (newline-and-indent)
  (scala-indent:insert-asterisk-on-multiline-comment))

(defun c-mode-newline-comments ()
  "Newline with indent and preserve multiline comments."
  (interactive)
  (c-indent-new-comment-line)
  (indent-according-to-mode))

(defun sbt-ctags ()
  (interactive)
  (sbt:command "genCtags"))

(use-package scala-mode
  :defer t
  :init
  (setq-default yatemplate-scala-header-skip nil)
  (put 'yatemplate-scala-header-skip 'safe-local-variable #'booleanp)
  (setq
   scala-indent:use-javadoc-style t
   scala-indent:align-parameters t)
  :config

  ;; prefer smartparens for parens handling
  (remove-hook 'post-self-insert-hook
               'scala-indent:indent-on-parentheses)

  (bind-key "RET" 'scala-mode-newline-comments scala-mode-map)
  (bind-key "s-<delete>" (sp-restrict-c 'sp-kill-sexp) scala-mode-map)
  (bind-key "s-<backspace>" (sp-restrict-c 'sp-backward-kill-sexp) scala-mode-map)
  (bind-key "s-<home>" (sp-restrict-c 'sp-beginning-of-sexp) scala-mode-map)
  (bind-key "s-<end>" (sp-restrict-c 'sp-end-of-sexp) scala-mode-map)
  ;; BUG https://github.com/Fuco1/smartparens/issues/468
  ;; backwards/next not working particularly well

  ;; i.e. bypass company-mode
  (bind-key "C-<tab>" 'dabbrev-expand scala-mode-map)

  (bind-key "<f12>" 'sbt-start scala-mode-map)
  (bind-key "C-c c" 'sbt-command scala-mode-map)
  (bind-key "C-c e" 'next-error scala-mode-map)

  ;; overrides projectile
  (bind-key "C-c p R" 'sbt-ctags scala-mode-map))

(use-package sbt-mode
  :commands sbt-start sbt-command
  :init
  (setq
   sbt:sbt-history-file ".history"
   sbt:ansi-support t
   sbt:prefer-nested-projects t
   sbt:scroll-to-bottom-on-output nil
   sbt:default-command "test:compile")
  (put 'sbt:default-command 'safe-local-variable #'stringp)
  :config
  ;; WORKAROUND: https://github.com/hvesalai/sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)

  ;; overrides projectile
  (bind-key "C-c p R" 'sbt-ctags sbt:mode-map)
  (bind-key "C-c c" 'sbt-command sbt:mode-map)
  (bind-key "C-c e" 'next-error sbt:mode-map))

(add-hook 'sbt-mode-hook
          (lambda ()
            (setq prettify-symbols-alist
                  `((,(expand-file-name (getenv "SBT_VOLATILE_TARGET")) . ?☣)
                    (,(expand-file-name (directory-file-name (projectile-project-root))) . ?§)
                    ("target/scala-2.12" . ?☢)
                    (,(expand-file-name "~") . ?~)))
            ;; for some reason, local variables are ignored without this
            ;;(hack-dir-local-variables-non-file-buffer)
            (hack-local-variables)
            (prettify-symbols-mode t)))

(defcustom
  scala-mode-prettify-symbols
  '(;;("->" . ?→)
    ;;("<-" . ?←)
    ;;("=>" . ?⇒)
    ;; ("<=" . ?≤)
    ;; (">=" . ?≥)
    ;; ("!=" . ?≠)
    ;; implicit https://github.com/chrissimpkins/Hack/issues/214
    ;;("+-" . ?±)
    ;; https://contributors.scala-lang.org/t/proposed-syntax-for--root-/1035/78?u=fommil
    ("_root_." . ?/)
    )
  "Prettify symbols for scala-mode.")

(add-hook 'scala-mode-hook
          (lambda ()
            (whitespace-mode-with-local-variables)
            (show-paren-mode t)
            (smartparens-mode t)
            (yas-minor-mode t)
            (git-gutter-mode t)
            (company-mode t)
            (setq prettify-symbols-alist scala-mode-prettify-symbols)
            (prettify-symbols-mode t)
            (scala-mode:goto-start-of-code)))

(use-package cc-mode
  :ensure nil
  :config
  (bind-key "C-c c" 'sbt-command java-mode-map)
  (bind-key "C-c e" 'next-error java-mode-map)
  (bind-key "RET" 'c-mode-newline-comments java-mode-map))

(add-hook 'java-mode-hook
          (lambda ()
            (whitespace-mode-with-local-variables)
            (show-paren-mode t)
            (smartparens-mode t)
            (yas-minor-mode t)
            (git-gutter-mode t)
            (company-mode t)))

(provide 'fommil-scala)

;;; fommil-scala.el ends here
