;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; Copyright (C) 2014 - 2015 Sam Halliday (fommil)
;; License: http://www.gnu.org/licenses/gpl.html

;; URL: https://github.com/fommil/dotfiles/blob/master/.emacs.d/init.el

;;; Commentary:
;;
;; This file is broken into sections which gather similar features or
;; modes together.  Sections are delimited by a row of semi-colons
;; (stage/functional sections) or a row of dots (primary modes).

;;; Code:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Site Local
(setq load-prefer-newer t)
(load (expand-file-name "local-preinit.el" user-emacs-directory) 'no-error)
(setq package-check-signature nil)
(unless (and (boundp 'package--initialized) package--initialized)
  ;; don't set gnu/org/melpa if the site-local or local-preinit have
  ;; done so (e.g. firewalled corporate environments)
  (require 'package)
  (setq
   package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                      ;;("org" . "http://orgmode.org/elpa/")
                      ("melpa-stable" . "http://stable.melpa.org/packages/")
                      ("melpa" . "http://melpa.org/packages/"))
   package-archive-priorities '(("melpa-stable" . 1))))
(package-initialize)
(unless (or
         (require 'use-package nil 'no-error)
         package-archive-contents)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for global settings for built-in emacs parameters
(setq
 inhibit-startup-screen t
 initial-scratch-message nil
 enable-local-variables t
 create-lockfiles nil
 make-backup-files nil
 custom-file (expand-file-name "custom.el" user-emacs-directory)
 column-number-mode t
 scroll-error-top-bottom t
 scroll-margin 15
 gc-cons-threshold 20000000
 large-file-warning-threshold 100000000
 user-full-name "Sam Halliday")

;; buffer local variables
(setq-default
 fill-column 80
 indent-tabs-mode nil
 default-tab-width 4)

(put 'compilation-skip-threshold 'safe-local-variable #'integerp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for global settings for built-in packages that autoload
(setq
 save-abbrevs 'silent
 help-window-select t
 show-paren-delay 0.5
 dabbrev-case-fold-search nil
 tags-case-fold-search nil
 tags-revert-without-query t
 tags-add-tables nil
 compilation-scroll-output 'first-error
 compilation-ask-about-save nil
 source-directory (getenv "EMACS_SOURCE")
 org-confirm-babel-evaluate nil
 nxml-slash-auto-complete-flag t
 sentence-end-double-space nil
 browse-url-browser-function 'browse-url-generic
 ediff-window-setup-function 'ediff-setup-windows-plain)

(setq-default
 c-basic-offset 4)

(add-hook 'prog-mode-hook
          (lambda () (setq show-trailing-whitespace t)))

;; protects against accidental mouse movements
;; http://stackoverflow.com/a/3024055/1041691
(add-hook 'mouse-leave-buffer-hook
          (lambda () (when (and (>= (recursion-depth) 1)
                           (active-minibuffer-window))
                  (abort-recursive-edit))))

;; *scratch* is immortal
(add-hook 'kill-buffer-query-functions
          (lambda () (not (member (buffer-name) '("*scratch*" "scratch.el")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for setup functions that are built-in to emacs
(defalias 'yes-or-no-p 'y-or-n-p)
(menu-bar-mode -1)
(when window-system
  (tool-bar-mode -1)
  (scroll-bar-mode -1))
(global-auto-revert-mode 1)

(electric-indent-mode 0)
(remove-hook 'find-file-hook 'vc-find-file-hook)

(global-auto-composition-mode 0)
(auto-encryption-mode 0)
(tooltip-mode 0)
(save-place-mode 1)

(make-variable-buffer-local 'tags-file-name)
(make-variable-buffer-local 'show-paren-mode)

(add-to-list 'auto-mode-alist '("\\.log\\'" . auto-revert-tail-mode))
(defun add-to-load-path (path)
  "Add PATH to LOAD-PATH if PATH exists."
  (when (file-exists-p path)
    (add-to-list 'load-path path)))
(add-to-load-path (expand-file-name "lisp" user-emacs-directory))

(add-to-list 'auto-mode-alist '("\\.xml\\'" . nxml-mode))
;; WORKAROUND http://debbugs.gnu.org/cgi/bugreport.cgi?bug=16449
(add-hook 'nxml-mode-hook (lambda () (flyspell-mode -1)))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer))

(use-package subword
  :ensure nil
  :diminish subword-mode
  :config (global-subword-mode 1))

(use-package dired
  :ensure nil
  :config
  (setq dired-dwim-target t))

(use-package xref
  :ensure nil
  :config
  (bind-key "<up>" #'xref-prev-line-quiet xref--xref-buffer-mode-map)
  (bind-key "<down>" #'xref-next-line-quiet xref--xref-buffer-mode-map))

(defun xref-next-line-quiet ()
  (interactive)
  (xref--search-property 'xref-item))
(defun xref-prev-line-quiet ()
  (interactive)
  (xref--search-property 'xref-item t))

(use-package elec-pair
  :ensure nil)
;; overwrite this built-in function from `elec-mode.el` with one that uses
;; `newline-and-indent` rather than `newline`.
(defun electric-pair-open-newline-between-pairs-psif ()
  "Honour `electric-pair-open-newline-between-pairs'.
Member of `post-self-insert-hook' if `electric-pair-mode' is on."
  (when (and (if (functionp electric-pair-open-newline-between-pairs)
                 (funcall electric-pair-open-newline-between-pairs)
               electric-pair-open-newline-between-pairs)
             (eq last-command-event ?\n)
             (< (1+ (point-min)) (point) (point-max))
             (eq (save-excursion
                   (skip-chars-backward "\t\s")
                   (char-before (1- (point))))
                 (matching-paren (char-after))))
    (save-excursion (newline-and-indent))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for generic interactive convenience methods.
;; Arguably could be uploaded to MELPA as package 'fommil-utils.
;; References included where shamelessly stolen.
(defun indent-buffer ()
  "Indent the entire buffer."
  (interactive)
  (save-excursion
    (delete-trailing-whitespace)
    (indent-region (point-min) (point-max) nil)
    (untabify (point-min) (point-max))))

(defun indent-defun ()
  "Indent the current function."
  (interactive)
  (save-mark-and-excursion
    (mark-defun)
    (indent-region (point) (mark))))

(defun unfill-paragraph (&optional region)
  ;; http://www.emacswiki.org/emacs/UnfillParagraph
  "Transforms a paragraph in REGION into a single line of text."
  (interactive)
  (let ((fill-column (point-max)))
    (fill-paragraph nil region)))

(defun unfill-buffer ()
  "Unfill the buffer for function `visual-line-mode'."
  (interactive)
  (let ((fill-column (point-max)))
    (fill-region 0 (point-max))))

(defun revert-buffer-no-confirm ()
  ;; http://www.emacswiki.org/emacs-en/download/misc-cmds.el
  "Revert buffer without confirmation."
  (interactive)
  (revert-buffer t t))

(defun contextual-backspace ()
  "Hungry whitespace or delete word depending on context."
  (interactive)
  (if (looking-back "[[:space:]\n]\\{2,\\}" (- (point) 2))
      (while (looking-back "[[:space:]\n]" (- (point) 1))
        (delete-char -1))
    (cond
     ((and (boundp 'smartparens-strict-mode)
           smartparens-strict-mode)
      (sp-backward-kill-word 1))
     ((and (boundp 'paredit-mode) paredit-mode)
      (paredit-backward-kill-word))
     (subword-mode
      (subword-backward-kill 1))
     (t
      (backward-kill-word 1)))))

(defun exit ()
  "Short hand for DEATH TO ALL PUNY BUFFERS!"
  (interactive)
  (if (daemonp)
      (message "You silly")
    (save-buffers-kill-emacs)))

(defun safe-kill-emacs ()
  "Only exit Emacs if this is a small session, otherwise prompt."
  (interactive)
  (if (daemonp)
      ;; intentionally not save-buffers-kill-terminal as it has an
      ;; impact on other client sessions.
      (delete-frame)
    ;; would be better to filter non-hidden buffers
    (let ((count-buffers (length (buffer-list))))
      (if (< count-buffers 11)
          (save-buffers-kill-emacs)
        (message-box "use 'M-x exit'")))))

(defun declare-buffer-bankruptcy ()
  "Declare buffer bankruptcy and clean up everything using `midnight'."
  (interactive)
  (let ((clean-buffer-list-delay-general 0)
        (clean-buffer-list-delay-special 0))
    (clean-buffer-list)))

(defcustom compile-with-directory-file
  "Makefile"
  "A filename indicating the `compile' dir."
  :type 'string
  :group 'tools
  :safe
  :local)
(defun compile-with-directory ()
  "`compile' but from a part directory that matches a predicate."
  (interactive)
  (let ((default-directory
         (or (locate-dominating-file default-directory compile-with-directory-file)
             default-directory)))
    (call-interactively #'compile)))

(defvar ido-buffer-whitelist
  '("^[*]\\(notmuch\\-hello\\|unsent\\|ag search\\|grep\\|eshell\\|magit\\([:]\\|-log\\|-diff\\)\\).*")
  "Whitelist regexp of `clean-buffer-list' buffers to show when switching buffer.")
(defun midnight-clean-or-ido-whitelisted (name)
  "T if midnight is likely to kill the buffer named NAME, unless whitelisted.
Approximates the rules of `clean-buffer-list'."
  (require 'midnight)
  (require 'dash)
  (cl-flet* ((buffer-finder (regexp) (string-match regexp name))
             (buffer-find (regexps) (-partial #'-find #'buffer-finder)))
    (and (buffer-find clean-buffer-list-kill-regexps)
         (not (or (buffer-find clean-buffer-list-kill-never-regexps)
                  (buffer-find ido-buffer-whitelist))))))

(defun company-or-dabbrev-complete ()
  "Force a `company-complete', falling back to `dabbrev-expand'."
  (interactive)
  (if company-mode
      (company-complete)
    (call-interactively 'dabbrev-expand)))

(defun company-backends-for-buffer ()
  "Calculate appropriate `company-backends' for the buffer.
For small projects, use TAGS for completions, otherwise use a
very minimal set."
  (projectile-visit-project-tags-table)
  (cl-flet ((size () (buffer-size (get-file-buffer tags-file-name))))
    (let ((base '(company-keywords company-dabbrev-code company-files)))
      (if (and tags-file-name (<= 20000000 (size)))
          (list (push 'company-etags base))
        (list base)))))

(defun plist-merge (&rest plists)
  "Create a single property list from all PLISTS.
Inspired by `org-combine-plists'."
  (let ((rtn (pop plists)))
    (dolist (plist plists rtn)
      (setq rtn (plist-put rtn
                           (pop plist)
                           (pop plist))))))

(defun dot-emacs ()
  "Go directly to .emacs, do not pass Go, do not collect $200."
  (interactive)
  (message "Stop procrastinating and do some work!")
  (find-file "~/.emacs.d/init.el"))

(defun display-ansi-colors ()
  "When opening a log file with ANSI escapes."
  (interactive)
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region (point-min) (point-max))))

(defun package-ensure-compiled (&optional alt)
  "Checks that all registered packages in ~/.emacs.d/elpa are compiled."
  (interactive "P")
  (seq-do
   (lambda (dir)
     (byte-recompile-directory dir 0))
   (seq-filter
    (lambda (dir)
      (and
       (string-prefix-p
        (expand-file-name package-user-dir)
        (expand-file-name dir))
       (file-writable-p dir)
       (or
        alt
        (not
         (directory-files
          dir t
          (rx bos (+ any) ".elc" eos))))))
    load-path)))

(defun shrug ()
  "Insert ASCII shrug dude."
  (interactive)
  (insert "¯\\_(ツ)_/¯"))

(defun table-flip ()
  "Insert an ASCII table flip."
  (interactive)
  (insert "(╯°□°）╯︵ ┻━┻)"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for global modes that should be loaded in order to
;; make them immediately available.

(use-package diminish) ;; optional dependency of use-package

(use-package midnight
  :init
  (setq
   clean-buffer-list-kill-regexps '("^[*].*")
   clean-buffer-list-kill-never-regexps
   '("^\\([#]\\|[*]\\(scratch\\|Messages\\)\\).*")))

(use-package persistent-scratch
  :config
  (persistent-scratch-setup-default)
  (setq persistent-scratch-what-to-save '(major-mode)))

(use-package undo-tree
  :diminish undo-tree-mode
  :init (setq undo-tree-auto-save-history nil)
  :config (global-undo-tree-mode)
  :bind ("s-/" . undo-tree-visualize))

(use-package flx-ido
  :demand
  :init
  (setq
   ido-enable-flex-matching t
   ido-use-faces nil ;; ugly
   ido-case-fold nil ;; https://github.com/lewang/flx#uppercase-letters
   ido-ignore-buffers '("\\` " midnight-clean-or-ido-whitelisted)
   ido-show-dot-for-dired nil ;; remember C-d
   ido-enable-dot-prefix t)
  :config
  (ido-mode 1)
  (ido-everywhere t)
  (flx-ido-mode 1))

(use-package projectile
  :demand
  ;; nice to have it on the modeline
  :init
  (put 'ag-ignore-list 'safe-local-variable #'listp)
  (setq-default
   ;; explicit -e here forces +Unknown lang parser
   projectile-tags-command "ctags -R -f \"%s\" %s \"%s\"")
  (setq
   projectile-tags-backend 'xref
   projectile-use-git-grep t
   projectile-globally-ignored-directories '(".git")
   projectile-indexing-method 'hybrid
   projectile-globally-ignored-files '("TAGS" "*.min.js"))
  :config
  (add-hook 'projectile-grep-finished-hook
            ;; not going to the first hit?
            (lambda () (pop-to-buffer next-error-last-buffer)))
  (make-variable-buffer-local 'projectile-tags-command)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (projectile-mode 1)
  :bind
  (("s-f" . projectile-find-file)
   ("s-F" . projectile-ag)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for loading and tweaking generic modes that are
;; used in a variety of contexts, but can be lazily loaded based on
;; context or when explicitly called by the user.
(use-package highlight-symbol
  :diminish highlight-symbol-mode
  :commands highlight-symbol
  :bind ("s-h" . highlight-symbol))

(use-package hl-todo
  :config (global-hl-todo-mode 1))

(use-package expand-region
  :commands 'er/expand-region
  :bind ("C-=" . er/expand-region))

(use-package goto-chg
  :commands goto-last-change
  ;; complementary to
  ;; C-x r m / C-x r l
  ;; and C-<space> C-<space> / C-u C-<space>
  :bind (("C-." . goto-last-change)
         ("C-," . goto-last-change-reverse)))

(use-package visual-regexp-steroids
  :commands vr/isearch-forward vr/query-replace
  :init (setq vr/engine 'pcre2el)
  :bind (("C-S-s" . vr/isearch-forward)
         ("s-S" . vr/query-replace)))

(use-package popup-imenu
  :commands popup-imenu
  :bind ("M-i" . popup-imenu))

;; WORKAROUND (missing in 2.9.4) https://github.com/magit/with-editor/issues/82
(use-package with-editor
  :pin melpa)

(use-package magit
  :commands magit-status magit-blame-addition
  :init (setq
         git-commit-style-convention-checks nil)
  :bind (("s-g" . magit-status)
         ("s-b" . magit-blame-addition)))

;; BLOCKED https://github.com/magit/forge/issues/21
;; BLOCKED https://github.com/magit/forge/issues/22
;; https://emacsair.me/2018/12/19/forge-0.1/
;;(use-package forge)

(use-package git-timemachine
  :commands git-timemachine
  :init (setq git-timemachine-abbreviation-length 4))

(use-package ag
  :commands ag
  :init
  (setq
   ag-reuse-window t
   ag-highlight-search t)
  :config
  (add-hook 'ag-search-finished-hook
            (lambda () (pop-to-buffer next-error-last-buffer))))

(use-package tidy
  ;; https://www.emacswiki.org/emacs/download/tidy.el
  :ensure nil
  :commands tidy-buffer)

(use-package company
  :diminish company-mode
  :commands company-mode
  :init
  (setq
   company-dabbrev-other-buffers t
   company-dabbrev-ignore-case nil
   company-dabbrev-code-ignore-case nil
   company-dabbrev-downcase nil
   company-dabbrev-minimum-length 4
   company-idle-delay 0
   company-minimum-prefix-length 4)
  :config
  ;; dabbrev is too slow, use C-TAB explicitly or add back on per-mode basis
  (delete 'company-dabbrev company-backends)
  ;; disables TAB in company-mode (too many conflicts)
  (define-key company-active-map [tab] nil)
  (define-key company-active-map (kbd "TAB") nil))

(use-package rainbow-mode
  :diminish rainbow-mode
  :commands rainbow-mode)

;; TODO show compile buffer output as flycheck squiggles
(use-package flycheck
  :pin melpa ;; for go-staticcheck
  :diminish flycheck-mode
  :commands flycheck-mode
  :init
  (setq flycheck-check-syntax-automatically '(mode-enabled save)
        flycheck-standard-error-navigation nil)
  :config
  ;; disables the timed popup, use C-h .
  (defun flycheck-display-error-at-point-soon ()))

(use-package yasnippet
  :diminish yas-minor-mode
  :commands yas-minor-mode
  :bind ("s-<tab>" . yas-expand)
  :config
  (yas-reload-all nil t))

(use-package yatemplate
  :defer 2 ;; WORKAROUND https://github.com/mineo/yatemplate/issues/3
  :init
  (setq auto-insert-alist nil)
  (setq-default yatemplate-license "http://www.gnu.org/licenses/lgpl-3.0.en.html")
  :config
  (auto-insert-mode 1)
  (yatemplate-fill-alist))

(use-package color-moccur
  :bind (("s-o" . moccur)
         :map isearch-mode-map
         ("M-o" . isearch-moccur)
         ("M-O" . isearch-moccur-all)))

(use-package whitespace
  :commands whitespace-mode
  :diminish whitespace-mode
  :init
  ;; BUG: https://emacs.stackexchange.com/questions/7743
  (put 'whitespace-style 'safe-local-variable #'listp)
  (put 'whitespace-line-column 'safe-local-variable #'integerp)
  (setq whitespace-style '(face trailing tabs)
        ;; add `lines-tail' to report long lines
        ;; github source code viewer overflows ~120 chars
        whitespace-line-column 120))
(defun whitespace-mode-with-local-variables ()
  "A variant of `whitespace-mode' that can see local variables."
  ;; WORKAROUND https://emacs.stackexchange.com/questions/7743
  (add-hook 'hack-local-variables-hook 'whitespace-mode nil t))

(use-package flyspell
  :commands flyspell-mode
  :diminish flyspell-mode
  :init (setq
         ispell-dictionary "british"
         flyspell-prog-text-faces '(font-lock-doc-face))
  :config
  (bind-key "C-." nil flyspell-mode-map)
  ;; the correct way to set flyspell-generic-check-word-predicate
  (put #'text-mode #'flyspell-mode-predicate #'text-flyspell-predicate))

(defun text-flyspell-predicate ()
  "Ignore acronyms and anything starting with 'http' or 'https'."
  (save-excursion
    (let ((case-fold-search nil))
      (forward-whitespace -1)
      (when
          (or
           (equal (point) (line-beginning-position))
           (looking-at " "))
        (forward-char))
      (not
       (looking-at "\\([[:upper:]]+\\|https?\\)\\b")))))

(use-package rainbow-delimiters
  :diminish rainbow-delimiters-mode
  :commands rainbow-delimiters-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for overriding common emacs keybindings with tweaks.
(global-unset-key (kbd "C-z")) ;; I hate you so much C-z
(global-set-key (kbd "C-x C-c") 'safe-kill-emacs)
(global-set-key (kbd "C-<backspace>") 'contextual-backspace)
(global-set-key (kbd "RET") 'newline-and-indent)
(global-set-key (kbd "M-.") 'projectile-find-tag)
(global-set-key (kbd "M-,") 'pop-tag-mark)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for defining commonly invoked commands that deserve
;; a short binding instead of their packager's preferred binding.
(global-set-key (kbd "C-<tab>") 'company-or-dabbrev-complete)
(global-set-key (kbd "s-s") 'replace-string)
(global-set-key (kbd "<f5>") 'revert-buffer-no-confirm)
(global-set-key (kbd "M-Q") 'unfill-paragraph)
(global-set-key (kbd "<f6>") 'dot-emacs)
(global-set-key (kbd "C-x \\") 'indent-defun)

;;..............................................................................
;; elisp
(use-package lisp-mode
  :ensure nil
  :commands emacs-lisp-mode
  :config
  (bind-key "RET" 'comment-indent-new-line emacs-lisp-mode-map)
  (bind-key "C-c c" 'emacs-lisp-cask-compile emacs-lisp-mode-map)

  (define-key emacs-lisp-mode-map (read-kbd-macro "DEL") nil))

(defun emacs-lisp-cask-compile ()
  (interactive)
  (if-let (default-directory
            (locate-dominating-file default-directory "Cask"))
      (call-interactively 'compile)
    (error "This is not a Cask project")))

(use-package flycheck-cask
  :pin melpa ;; to match unstable flycheck
  )
(add-hook 'flycheck-mode-hook #'flycheck-cask-setup)

(use-package eldoc
  :ensure nil
  :diminish eldoc-mode
  :config
  (eldoc-add-command
   'paredit-backward-delete
   'paredit-close-round)
  :commands eldoc-mode)
(global-eldoc-mode -1)

(use-package pcre2el
  :commands rxt-toggle-elisp-rx
  :init (bind-key "C-c / t" 'rxt-toggle-elisp-rx emacs-lisp-mode-map))

(use-package re-builder
  :ensure nil
  ;; C-c C-u errors, C-c C-w copy, C-c C-q exit
  :init (bind-key "C-c r" 're-builder emacs-lisp-mode-map))

(use-package json-mode)

(defun paredit-unwrap ()
  "Unwrap the s-expression at point."
  (interactive)
  (save-excursion
    (if (looking-at (rx (syntax open-parenthesis)))
        (forward-char)
      (re-search-forward (rx point (* space) (syntax open-parenthesis))))
    (paredit-splice-sexp)))

;; makes `insert-parentheses' behave like `paredit-insert-pair'
(advice-add
 #'insert-parentheses
 :filter-args
 #'(lambda (a) (if (equal a '(nil)) '(1) a)))

(use-package paredit
  :config
  ;; paredit aggressively creates hardcoded bindings, and many of those bindings
  ;; are exceptionally irritating. The only way to undo it is to rerun the
  ;; initialisation logic and unset every binding (or to unbind just the
  ;; annoying things, but being explicit about what is in scope is best).
  (paredit-do-commands (spec keys _fn _examples) nil
    (dolist (key keys)
      (define-key paredit-mode-map (read-kbd-macro key) nil)))
  :bind
  (:map
   paredit-mode-map
   ;; The following bindings are the subset of paredit that are useful and not
   ;; already covered by additions to stock emacs.
   ;;
   ;; Some reminders of stock commands:
   ;;
   ;; - `C-M-k' already does `kill-sexp' (negative prefix works for backward)
   ;; - `C-M-{f,b,u,d,p,n}' are already bound to s-exp navigation
   ;; - `M-(' already bound to `insert-parentheses'
   ("(" . paredit-open-round)
   (")" . paredit-close-round)
   ("[" . paredit-open-square)
   ("]" . paredit-close-square)
   (";" . paredit-semicolon)

   ;; splice means to remove outer parens
   ("DEL" . paredit-backward-delete)
   ("M-<delete>" . paredit-unwrap)
   ("M-s" . paredit-splice-sexp)
   ("M-<up>" . paredit-splice-sexp-killing-backward)
   ("M-r" . paredit-raise-sexp) ;; like `M-<up>' but kills both sides
   ("M-<down>" . paredit-splice-sexp-killing-forward)

   ;; questionable bindings, might be axed
   ("M-;" . paredit-comment-dwim)
   ("\"" . paredit-doublequote)
   ("\\" . paredit-backslash)
   ("M-d" . paredit-forward-kill-word)
   ("M-DEL" . paredit-backward-kill-word)
   ("M-S" . paredit-split-sexp)
   ("M-J" . paredit-join-sexps)))

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq show-trailing-whitespace t)
            (setq-local compile-command "cask exec ert-runner")

            ;; the default elisp--xref-backend is C-h f, not TAGS lookup
            (setq xref-backend-functions '(etags--xref-backend))

            ;; disable emacs-lisp-checkdoc
            (setq-local flycheck-checkers '(emacs-lisp))
            (show-paren-mode 1)
            (whitespace-mode-with-local-variables)
            (rainbow-mode 1)
            (prettify-symbols-mode 1)
            (eldoc-mode 1)
            (flycheck-mode 1)
            (yas-minor-mode 1)
            (company-mode 1)
            (paredit-mode 1)
            ;; paredit default bindings are fucking horrid
            ;;(setq paredit-mode-map nil)
            (rainbow-delimiters-mode 1)))

;;..............................................................................
;; C
(add-hook 'c-mode-hook (lambda ()
                         (yas-minor-mode 1)
                         (company-mode 1)
                         (electric-pair-local-mode 1)))

;;..............................................................................
;; IRC
(use-package erc
  :commands erc erc-tls
  :init
  (setq
   erc-prompt-for-password nil ;; prefer ~/.authinfo for passwords
   erc-hide-list '("JOIN" "PART" "QUIT" "MODE")))
(add-hook 'erc-mode 'erc-spelling-mode)

;; WORKAROUND: https://github.com/leathekd/erc-hl-nicks/issues/11
(use-package erc-hl-nicks
  :init
  (setq erc-hl-nicks-skip-nicks '("so")))
(custom-set-faces
 '(erc-nick-default-face ((t nil))))

;;..............................................................................
;; Miscellaneous editing modes
(use-package yaml-mode
  :mode ((rx ".yml" eos) . yaml-mode))

(use-package dockerfile-mode
  :mode ((rx "Dockerfile" eos) . dockerfile-mode))

;; I'd prefer this to go to the minibuffer, but a box it is...
(use-package eldoc-box)

;; I don't use a lot of LSP features, so turn them off
(use-package eglot
  :ensure nil
  :config
  (setq
   eglot-report-progress nil
   eglot-ignored-server-capabilities
   ;; the things we actually want are uncommented here. Weird
   ;; way to do it, but ok.
   '(;:hoverProvider ;(provides async type info, would like this to be manual)
     ;:completionProvider (provides company with completions)
     ;:signatureHelpProvider (eldoc integration, unsure entirely what it does)
     ;:definitionProvider (M-. jump to definition)
     :typeDefinitionProvider
     :implementationProvider
     :declarationProvider
     :referencesProvider
     :documentHighlightProvider
     :documentSymbolProvider
     :workspaceSymbolProvider
     ;:codeActionProvider (quickfix is useful, e.g. import type at point)
     :codeLensProvider
     :documentFormattingProvider
     :documentRangeFormattingProvider
     :documentOnTypeFormattingProvider
     :renameProvider
     :documentLinkProvider
     :colorProvider
     :foldingRangeProvider
     :executeCommandProvider
     :inlayHintProvider))
  (add-to-list 'eglot-stay-out-of 'flymake) ;; disable diagnostics, needs server support
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode rust-mode) .
                 ("rust-analyzer"
                  :initializationOptions
                  (:checkOnSave :json-false :diagnostics (:enable :json-false)))))
  :bind
  (:map eglot-mode-map
        ("C-c C-r i" . eglot-code-action-quickfix)
        ;("C-c C-i t" . eldoc-print-current-symbol-info)
        ("C-c C-i t" . eldoc-box-help-at-point)))

(add-hook
 'eglot-managed-mode-hook
 (lambda ()
   ;; we want eglot to setup callbacks from eldoc, but we don't want eldoc
   ;; running after every command. As a workaround, we disable it after we just
   ;; enabled it. Now calling `M-x eldoc` will put the help we want in the eldoc
   ;; buffer. Alternatively we could tell eglot to stay out of eldoc, and add
   ;; the hooks manually, but that seems fragile to updates in eglot.
   (eldoc-mode -1)))

(require 'fommil-email)
(require 'fommil-haskell-tng)
(require 'fommil-python)
(require 'fommil-manuscripts)

(use-package scala-mode
  :mode ((rx (| ".scala" ".sbt") eos) . scala-mode)
  :config
  (require 'scala-compile)
  (require 'scala-organise)
  :bind
  (:map scala-mode-map
        ("M-<delete>" . paredit-unwrap)
        ("C-c c" . scala-compile)
        ("C-c C-r f" . scala-organise))
  :hook
  ((scala-mode . show-paren-mode)
   (scala-mode . electric-pair-local-mode)
   (scala-mode . yas-minor-mode)))

(use-package ensime-mode
  :ensure nil
  :load-path "~/Projects/ensime-tng/lisp"
  :commands ensime-mode
  :bind
  (:map ensime-mode-map
        ("M-." . ensime-jump-to-definition)
        ("C-c C-i t" . ensime-type-at-point)
        ("C-c C-i s" . ensime-symbol-at-point)
        ("C-c C-r i" . ensime-import-symbol-at-point)))

(add-hook 'scala-mode-hook #'ensime-mode)

(use-package javap-mode)

(use-package go-mode
  ;; Make sure to install dependencies:
  ;;
  ;; go install golang.org/x/tools/cmd/goimports@latest
  ;; go install github.com/rogpeppe/godef@latest
  ;; go install github.com/stamblerre/gocode@latest
  ;; go install honnef.co/go/tools/cmd/staticcheck@latest
  ;;
  ;; go install golang.org/x/tools/gopls@latest
  ;;
  ;; Note: gocode and godef is unmaintained but it should be possible to write a
  ;; gopls (non-lsp) based company/go-to-definition/eldoc backend. e.g. use the
  ;; `gopls references ast.go:87:6' feature, lookup each of the entries, and
  ;; retain the lines that are OOP methods. We could also use grep on the local
  ;; mod dir (assuming it has been tided) to fuzzy find type methods (which
  ;; could be cross referenced with gopls references or fqn of types confirmed).
  ;; We could also use the `go doc` tool to list contents of a package, again
  ;; needing package name lookup. TODO gopls backends
  ;; TODO https://github.com/golang/go/issues/52069
  ;;
  ;; go install github.com/pquerna/ffjson@latest
  ;; https://yalantis.com/blog/speed-up-json-encoding-decoding/
  ;;
  ;; TODO is there something like hoogle for Go?
  ;; TODO can https://github.com/haya14busa/gosum be ressurected?
  ;; TODO collapse trivial error handling code blocks
  ;; TODO snippets for trivial error handling
  :config
  (setq
   gofmt-command "goimports"
   gofmt-show-errors nil
   go-fontify-function-calls nil)
  :bind
  (:map
   go-mode-map
   ("C-c e" . next-error)
   ("C-c C-r f" . gofmt)
   ("C-c C-i t" . godef-describe)
   ("M-." . godef-jump)
   ("M-<delete>" . paredit-unwrap))
  :hook
  (;;(go-mode . abbrev-mode)
   (go-mode . show-paren-mode)
   (go-mode . electric-pair-local-mode)
   (go-mode . yas-minor-mode)
   (go-mode . flycheck-mode)
   (go-mode . company-mode)))
(use-package company-go
  :config
  (setq company-go-show-annotation t
        company-go-insert-arguments t))

(add-hook
 'go-mode-hook
 (lambda ()
   (setq-local flycheck-checker 'go-staticcheck)
   (setq-local company-backends '(company-files company-go (company-dabbrev-code company-etags)))
   ))

(use-package rust-mode
  :init
  (setq rust-format-on-save nil
        rust-format-show-buffer nil
        rust-format-goto-problem nil)
  :config
  (setq compile-with-directory-file "Cargo.toml"
        compile-command "cargo fmt && cargo build")
  :bind
  (:map rust-mode-map
        ("M-<delete>" . paredit-unwrap)
        ("C-c c" . compile-with-directory)
        ;; C-c C-f is rust-format-buffer
        ;; ("C-c C-r i" . eglot-code-action-quickfix)
        )
  :hook
  ((rust-mode . show-paren-mode)
   (rust-mode . electric-pair-local-mode)
   (rust-mode . yas-minor-mode)
   (rust-mode . eglot-ensure)
   (rust-mode . company-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OS specific
(pcase system-type
  (`gnu/linux
   (load (expand-file-name "init-gnu.el" user-emacs-directory))))

(use-package darcula-theme
  :init (setq darcula-background "#1b1b1b"))
(use-package intellij-theme)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Themes
(defun dark-theme ()
  "A dark coloured theme for hacking when there is no screen glare."
  (interactive)
  (load-theme 'darcula t))

(defun light-theme ()
  "A light coloured theme for hacking when there is lots of screen glare."
  (interactive)
  (load-theme 'intellij t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Site Local
(load (expand-file-name "local.el" user-emacs-directory) 'no-error)
(load (expand-file-name "local.sec.el" user-emacs-directory) 'no-error)

;;; init.el ends here
