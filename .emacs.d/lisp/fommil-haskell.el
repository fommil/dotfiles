;;; fommil-haskell.el --- Haskell Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;; Support for the Haskell language and ecosystem.
;;
;; Haskell workflow wants:
;;
;; - scrap ghc-env, too many tools. Use "with-compiler: ghc-7.10.3"
;;   and only have these binaries in bin, cabal discovers the rest.
;;   https://github.com/sol/ghc-env for binary downloads
;; - haskell-compile for running tests, with regex hits
;;   (replace `haskell-compile' with a hydra that remembers the last command)
;; - compile just one file, with cabal, to avoid long lags (ideally with squiggly)
;; - see / expand all members in an import (:browse at point)
;; - type at point (in minibuffer)
;;   haskell-doc-mode is too hacky and limited for my tastes,
;;   https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/ghci.html#ghci-cmd-:type-at
;;   https://ghc.haskell.org/trac/ghc/ticket/15461
;;   hmm... seems it is using the interactive shell already. But I don't like the eldoc nature of it.
;; - convert values to types https://twitter.com/jyothsnasrin/status/1039530556080283648
;; - summarise an ADT when type-at-point is used on an explicit type param (also popup version)
;; - jump to source of symbol at point
;;   maybe ctags are enough, https://github.com/MarcWeber/hasktags
;; - import from current point by (existing) symbol name
;; - import from current point by (popup) symbol search
;; - import from current point by (popup) hoogle search (or hayoo)
;; - popup (transitive) view hoogle / hayoo results
;; - manage language extensions from point
;; - documentation links for language extensions (e.g. eldocs readnig from the relevant part of the manual)
;; - cleanup imports
;; - format on save / compile (hindent / brittany)
;; - or at least local alignment
;; - flycheck inline errors
;; - jump to imports and back
;;   (maybe solved with imenu already)
;; - convert () and $ notation
;; - specifying / calculating the repl target on startup per file
;; - expand name of currently scoped function, with patterns
;; - better indent behaviour, it never seems to get it right
;;   on that note, yasnippet tab expansion messes with indentation
;; - writing "left to right" vs "right to left", is there a way to jump?
;; - gen instance typesig boilerplate
;; - send >>> commands in the region to the repl
;; - use stack freeze files from cabal, e.g. https://www.stackage.org/lts-12.9/cabal.config
;; - doctest (for running >>> things)
;;   https://github.com/sol/doctest/issues/209
;; - figure out how to use tasty patterns
;;   https://ro-che.info/articles/2018-01-08-tasty-new-patterns
;; - and tasty-discover
;; - and autogen things for `missing-home-modules'
;; - something like scalac-profiling
;; - limit the stack / heap memory
;; - semanticdb approach to docs (and more): hi-haddock / .hie (!= HIE) / underground project
;; - intero "apply suggestions" looks really useful
;;
;;; Code:

(use-package haskell-mode
  :pin melpa
  :init
  (put 'haskell-compile-command 'safe-local-variable #'stringp)
  (setq haskell-doc-show-prelude nil)
  :config
  (bind-key "C-c i" 'haskell-doc-show-type haskell-mode-map)
  (bind-key "C-c t" 'haskell-cabal-tasty haskell-mode-map)
  (bind-key "C-c c" 'haskell-compile haskell-mode-map)
  (bind-key "C-c e" 'next-error haskell-mode-map))

(require 'haskell-compile)
(add-hook 'haskell-mode-hook
          (lambda ()
            (haskell-doc-mode -1) ;; I don't like the eldoc style...
            (whitespace-mode-with-local-variables)
            (show-paren-mode t)
            (smartparens-mode t)
            (yas-minor-mode t)
            (git-gutter-mode t)
            (company-mode t)
            ;;(prettify-symbols-mode t)
            ;; needs https://github.com/elaforge/fast-tags/pull/43
            (setq projectile-tags-command "fast-tags -Re --exclude=.stack-work --exclude=dist-newstyle .")
            (setq company-backends (company-backends-for-buffer))))

(setq haskell-compile-cabal-build-command "cd %s && cabal new-build -O0")
(setq haskell-cabal-tasty-command "cd %s && cabal new-run tasty -- --timeout=10s --color=always")

;; what's the right scope for this?
(setq haskell-cabal-tasty-last nil)
(defun haskell-cabal-tasty (&optional edit)
  "Invokes `cabal tasty', with an optional pattern restriction."
  (interactive "P")
  (save-some-buffers (not compilation-ask-about-save)
                     compilation-save-buffers-predicate)
  (let* ((cabdir (haskell-cabal-find-dir))
         (base (format haskell-cabal-tasty-command cabdir))
         (restriction (if edit
                        (let ((custom (compilation-read-command "")))
                          (unless (string-empty-p custom)
                            (format " --pattern=%s" custom)))
                        haskell-cabal-tasty-last))
         (command (concat base restriction)))
    (setq haskell-cabal-tasty-last restriction)
    (compilation-start command 'haskell-compilation-mode)))

(provide 'fommil-haskell)

;;; fommil-haskell.el ends here
