;;; init-linux.el --- Appended to init for GNU boxen -*- lexical-binding: t -*-

;; Copyright (C) 2015 Sam Halliday
;; License: http://www.gnu.org/licenses/gpl.html

;;; Commentary:
;;
;;  Some packages only make sense on GNU/Linux, typically because of
;;  external applications.  This is where they go.
;;
;;; Code:

;; keeps flycheck happy
(require 'use-package)

;; while testing 25.1
;;(setq debug-on-error t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for loading and tweaking generic modes that are
;; used in a variety of contexts, but can be lazily loaded based on
;; context or when explicitly called by the user.

(setq
 ;; allows projectile to see .log files, even though git ignores them
 projectile-git-command "cat <(git ls-files -zco --exclude-standard) <(find . -name '*.log' -maxdepth 4 -print0)")

(when (display-graphic-p)
  (setq
   browse-url-generic-program "chromium"
   x-select-enable-clipboard t
   interprogram-paste-function 'x-cut-buffer-or-selection-value))

(use-package ess-site
  :ensure ess
  :mode ("\\.R\\'" . R-mode))

(use-package package-utils)

(use-package flycheck-cask
  :commands flycheck-cask-setup
  :init
  (eval-after-load 'flycheck
    '(add-hook 'flycheck-mode-hook #'flycheck-cask-setup)))

(use-package elnode
  :commands elnode-make-webserver)

(use-package erc
  :commands erc erc-tls
  :init
  (setq
   erc-prompt-for-password nil ;; prefer ~/.authinfo for passwords
   erc-hide-list '("JOIN" "PART" "QUIT")
   erc-autojoin-channels-alist
   '(("irc.freenode.net" "#emacs")
     ("irc.gitter.im" "#ensime/ensime-server" "#ensime/ensime-emacs"))))

(use-package yaml-mode
  :mode ("\\.yml\\'" . yaml-mode))

(use-package dockerfile-mode
  :mode ("Dockerfile\\'" . dockerfile-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for loading and configuring more involved
;; task/function-specific modes, organised by task or function.
;;..............................................................................
;; Email
(setq
 smtpmail-smtp-server "smtp.gmail.com"
 smtpmail-stream-type 'starttls
 smtpmail-smtp-service 587
 mail-user-agent 'message-user-agent
 user-mail-address "Sam.Halliday@gmail.com"
 send-mail-function 'smtpmail-send-it
 message-auto-save-directory (concat user-emacs-directory "drafts")
 message-kill-buffer-on-exit t
 message-signature "Best regards,\nSam\n"
 notmuch-search-line-faces '(("unread" :weight bold)
                             ("flagged" :inherit 'font-lock-string-face))
 notmuch-fcc-dirs nil
 notmuch-search-oldest-first nil
 notmuch-address-command "notmuch-addrlookup"
 notmuch-saved-searches '((:name "inbox" :key "i" :query "tag:inbox")
                          (:name "unread" :key "u" :query "tag:unread")
                          (:name "flagged" :key "f" :query "tag:flagged")
                          (:name "drafts" :key "d" :query "tag:draft")
                          (:name "all" :key "a" :query "*")))
(use-package notmuch
  :commands notmuch
  :config
  (add-hook 'message-setup-hook #'company-mode)
  ;; BUG https://debbugs.gnu.org/cgi/bugreport.cgi?bug=23747
  (add-hook 'message-setup-hook #'mml-secure-sign-pgpmime)
  )

;;..............................................................................
;; Clojure

(use-package flycheck-clojure)
(use-package flycheck-pos-tip)
(use-package cider
  :commands cider-jack-in
  :config
  (bind-key "C-c c" 'compile clojure-mode-map)
  (bind-key "C-c e" 'next-error clojure-mode-map))
(defalias 'cider 'cider-jack-in)
(add-hook 'clojure-mode-hook
          (lambda ()
            (show-paren-mode t)
            ;;(focus-mode t)
            (rainbow-mode t)
            (eldoc-mode t)

            ;; BUG https://github.com/clojure-emacs/squiggly-clojure/issues/39
            (flycheck-clojure-setup)
            (flycheck-mode t)
            (flycheck-pos-tip-mode t)

            (yas-minor-mode t)
            (company-mode t)
            (smartparens-strict-mode t)
            (rainbow-delimiters-mode t)))

(add-hook 'cider-repl-mode-hook #'eldoc-mode)

;;..............................................................................
;; Python
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

;;..............................................................................
;; shell scripts
(add-hook 'sh-mode-hook #'electric-indent-local-mode)

;;..............................................................................
(use-package synosaurus
  :commands synosaurus-choose-and-replace
  :init (setq synosaurus-choose-method 'popup)
  :config
  (bind-key "C-c s r" 'synosaurus-choose-and-replace text-mode-map))

(use-package writegood-mode
  :commands writegood-mode)

(defun writing-mode-hooks ()
  "Common hooks for writing modes."
  ;;(setq company-backends '(company-yasnippet))
  (flyspell-mode)
  (writegood-mode))
;; performance problems in emacs 24.5 (e.g. email)
;;(add-hook 'text-mode-hook #'writing-mode-hooks)
(add-hook 'org-mode-hook #'writing-mode-hooks)
(add-hook 'markdown-mode-hook #'writing-mode-hooks)

(use-package graphviz-dot-mode)

(defun markdown-flyspell-predicate ()
  "Refine the default text predicate to ignore markdown specific things."
  (and
   (text-flyspell-predicate)
   (not
    ;; this relies on faces so doesn't work if flyspell-buffer is
    ;; called before faces are available (e.g. in a hook)
    (let ((f (get-text-property (- (point) 1) 'face)))
      (member f '(markdown-pre-face markdown-language-keyword-face))))))
(put #'markdown-mode #'flyspell-mode-predicate #'markdown-flyspell-predicate)

(defun pandoc ()
  "If a hidden .pandoc file exists for the file, run it."
  ;; this effectively replaces pandoc-mode for me
  (interactive)
  (let ((command-file (concat (file-name-directory buffer-file-name)
                              "." (file-name-nondirectory buffer-file-name)
                              ".pandoc")))
    (when (file-exists-p command-file)
      (shell-command command-file))))

(use-package ox-leanpub
  :commands org-leanpub-export-to-markdown
  :ensure nil)

;; https://lakshminp.com/publishing-book-using-org-mode
(use-package ox-gfm)
(defun leanpub-export ()
  "Export buffer to a Leanpub book."
  (interactive)
  (if (file-exists-p "./Book.txt")
      (delete-file "./Book.txt"))
  (if (file-exists-p "./Sample.txt")
      (delete-file "./Sample.txt"))
  (org-map-entries
   (lambda ()
     (let* ((level (nth 1 (org-heading-components)))
            (tags (org-get-tags))
            (title (or (nth 4 (org-heading-components)) ""))
            (book-slug (org-entry-get (point) "TITLE"))
            (filename
             (or (org-entry-get (point) "EXPORT_FILE_NAME")
                 (concat (replace-regexp-in-string " " "-" (downcase title)) ".md"))))
       (when (= level 1) ;; export only first level entries
         ;; add to Sample book if "sample" tag is found.
         (when (member "sample" tags)
           (append-to-file (concat filename "\n\n") nil "./Sample.txt"))
         (when (member "final" tags)
           (append-to-file (concat filename "\n\n") nil "./Book.txt"))
         ;; set filename only if the property is missing
         (or (org-entry-get (point) "EXPORT_FILE_NAME")
             (org-entry-put (point) "EXPORT_FILE_NAME" filename))
         (org-leanpub-export-to-markdown nil 1 nil))))
   "-noexport")
  (org-save-all-org-buffers)
  nil nil)

;;..............................................................................
;; Chat rooms
(defun gitter()
  "Connect to Gitter."
  (interactive)
  (erc-tls :server "irc.gitter.im" :port 6697))
(defun freenode()
  "Connect to Freenode."
  (interactive)
  (erc :server "irc.freenode.net" :port 6667))

;;; init-linux.el ends here
