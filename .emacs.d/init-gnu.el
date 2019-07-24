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
   browse-url-generic-program "firefox"
   x-select-enable-clipboard t
   interprogram-paste-function 'x-cut-buffer-or-selection-value))

;; (use-package ess-site
;;   :ensure ess
;;   :mode ("\\.R\\'" . R-mode))

(use-package package-utils)

;; (use-package flycheck-cask
;;   :commands flycheck-cask-setup
;;   :init
;;   (eval-after-load 'flycheck
;;     '(add-hook 'flycheck-mode-hook #'flycheck-cask-setup)))

;; (use-package elnode
;;   :commands elnode-make-webserver)

;;..............................................................................
;; shell scripts
(add-hook 'sh-mode-hook #'electric-indent-local-mode)

;;..............................................................................
;; (use-package synosaurus
;;   :commands synosaurus-choose-and-replace
;;   :init (setq synosaurus-choose-method 'popup)
;;   :config
;;   (bind-key "C-c s r" 'synosaurus-choose-and-replace text-mode-map))

(use-package graphviz-dot-mode)

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
  (org-save-all-org-buffers))

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
