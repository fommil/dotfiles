;;; fommil-haskell.el --- Haskell Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;; Support for the Haskell language and ecosystem.
;;
;;; Code:

(defcustom
  haskell-mode-prettify-symbols
  '(("forall" . ?∀))
  "Prettify symbols for haskell-mode.")

(use-package haskell-mode
  :pin melpa
;;  :ensure nil ;; local build disables `package' / autoloading
  :init
  (put 'haskell-compile-command 'safe-local-variable #'stringp)
  (put 'haskell-compile-ghc-build-command 'safe-local-variable #'stringp)
  (put 'haskell-compile-ghc-build-alt-command 'safe-local-variable #'stringp)
  (put 'haskell-compile-stack-build-command 'safe-local-variable #'stringp)
  (put 'haskell-compile-stack-build-alt-command 'safe-local-variable #'stringp)
  (put 'haskell-compile-cabal-build-command 'safe-local-variable #'stringp)
  (put 'haskell-compile-cabal-build-alt-command 'safe-local-variable #'stringp)
  (put 'flycheck-ghc-language-extensions 'safe-local-variable #'flycheck-string-list-p)

  (setq haskell-doc-show-prelude nil)
  :config

  (bind-key "C-c c" 'haskell-compile haskell-mode-map)
  (bind-key "C-c e" 'next-error haskell-mode-map)

  (require 'haskell-compile)
  (bind-key "C-c c" 'haskell-compile haskell-compilation-mode-map)
  (bind-key "C-c e" 'next-error haskell-compilation-mode-map)

  (require 'haskell-cabal)
  (bind-key "C-c c" 'haskell-compile haskell-cabal-mode-map)
  (bind-key "C-c e" 'next-error haskell-cabal-mode-map)

  (bind-key "C-c C-r f" 'stylish-haskell haskell-mode-map)

  ;; i.e. bypass company-mode
  (bind-key "C-<tab>" 'dabbrev-expand haskell-mode-map))

(use-package hlint-refactor
  :config
  (bind-key "C-c C-r b" 'hlint-refactor-refactor-buffer haskell-mode-map)
  (bind-key "C-c C-r r" 'hlint-refactor-refactor-at-point haskell-mode-map))

(defun stylish-haskell ()
  "Apply `stylish-haskell' rules."
  (interactive)
  (save-buffer)
  (call-process "stylish-haskell" nil nil nil "-i" buffer-file-name)
  (revert-buffer t t t))

(require 'haskell-compile)
(add-hook 'haskell-mode-hook
          (lambda ()
            (haskell-doc-mode -1) ;; I don't like the eldoc style...
            (whitespace-mode-with-local-variables)
            (show-paren-mode 1)
            (smartparens-mode 1)
            (yas-minor-mode 1)
            (git-gutter-mode 1)
            (company-mode 1)

            (setq prettify-symbols-alist haskell-mode-prettify-symbols)
            (prettify-symbols-mode t)

            (setq projectile-tags-command "fast-tags -Re --exclude=.stack-work --exclude=dist-newstyle .")
            (setq company-backends (company-backends-for-buffer))))

(setq haskell-compile-cabal-build-command "cabal v2-build -O0")
(setq haskell-compile-cabal-build-alt-command "cabal v2-clean")

;; customises the stock behaviour to only support cabal, prefering cabal.project files
(defun haskell-compile (&optional edit-command)
  (interactive "P")
  (save-some-buffers (not compilation-ask-about-save) compilation-save-buffers-predicate)
  (when-let (cabaldir (or (locate-dominating-file default-directory "cabal.project")
                          (locate-dominating-file default-directory "cabal.project.local")
                          (locate-dominating-file default-directory "cabal.project.freeze")
                          (locate-dominating-file default-directory "cabal.config")
                          (haskell-cabal-find-dir)))
    (haskell--compile cabaldir edit-command
                      'haskell--compile-cabal-last
                      haskell-compile-cabal-build-command
                      haskell-compile-cabal-build-alt-command)))

(provide 'fommil-haskell)

;;; fommil-haskell.el ends here
