;;; fommil-haskell.el --- Haskell Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  Support for the Haskell language and ecosystem.
;;
;;; Code:

(use-package haskell-mode
  :init
  (put 'haskell-compile-command 'safe-local-variable #'stringp)
  (setq haskell-doc-show-prelude nil)
  :config
  (bind-key "C-c i" 'haskell-doc-show-type haskell-mode-map)
  (bind-key "C-c t" 'haskell-cabal-tasty haskell-mode-map)
  (bind-key "C-c c" 'haskell-compile haskell-mode-map))

(require 'haskell-compile)
(add-hook 'haskell-mode-hook
          (lambda ()
            (eldoc-mode -1) ;; I prefer explicit requests for types...
            (whitespace-mode-with-local-variables)
            (show-paren-mode t)
            (smartparens-mode t)
            (yas-minor-mode t)
            (git-gutter-mode t)
            (company-mode t)
            (setq prettify-symbols-alist scala-mode-prettify-symbols)
            (prettify-symbols-mode t)
            (setq company-backends (company-backends-for-buffer))))

;; what's the right scope for this?
(setq haskell-cabal-tasty-last nil)
(defun haskell-cabal-tasty (&optional edit)
  "Invokes `cabal tasty', with an optional pattern restriction."
  (interactive "P")
  (save-some-buffers (not compilation-ask-about-save)
                     compilation-save-buffers-predicate)
  (let* ((cabdir (haskell-cabal-find-dir))
         (base (format "cd %s && cabal test tasty --test-option=--timeout=10s --show-detail=direct --test-option=--color=always" cabdir))
         (restriction (if edit
                        (let ((custom (compilation-read-command "")))
                          (unless (string-empty-p custom)
                            (format " --test-option=--pattern=%s" custom)))
                        haskell-cabal-tasty-last))
         (command (concat base restriction)))
    (setq haskell-cabal-tasty-last restriction)
    (compilation-start command 'haskell-compilation-mode)))

;; Haskell workflow wants:
;;
;; - haskell-compile for running tests, with regex hits
;;   (replace `haskell-compile' with a hydra that remembers the last command)
;; - see / expand all members in an import (:browse at point)
;; - type at point (in minibuffer)
;;   haskell-doc-mode is too hacky and limited for my tastes
;; - jump to source of symbol at point
;;   maybe ctags are enough, https://github.com/MarcWeber/hasktags
;; - import from current point by (existing) symbol name
;; - import from current point by (popup) symbol search
;; - import from current point by (popup) hoogle search
;; - popup (transitive) view hoogle results
;; - manage language extensions from point
;; - cleanup imports
;; - format on save / compile (hindent / brittany)
;; - flycheck inline errors
;; - jump to imports and back
;; - convert () and $ notation
;; - (for irc) erc should hide short usernames (god damn you `so')
;;   https://emacs.stackexchange.com/questions/3749
;; - specifying / calculating the repl target on startup per file
;; - expand name of currently scoped function, with patterns
;; - colour output when running tasty tests

(provide 'fommil-haskell)

;;; fommil-haskell.el ends here
