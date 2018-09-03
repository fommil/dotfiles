;;; fommil-haskell.el --- Haskell Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;; Support for the Haskell language and ecosystem.
;;
;; Haskell workflow wants:
;;
;; - haskell-compile for running tests, with regex hits
;;   (replace `haskell-compile' with a hydra that remembers the last command)
;; - see / expand all members in an import (:browse at point)
;; - type at point (in minibuffer)
;;   haskell-doc-mode is too hacky and limited for my tastes,
;;   https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/ghci.html#ghci-cmd-:type-at
;;   https://ghc.haskell.org/trac/ghc/ticket/15461
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
;; - specifying / calculating the repl target on startup per file
;; - expand name of currently scoped function, with patterns
;; - colour output when running tasty tests
;;
;;; Code:

(use-package haskell-mode
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
            (haskell-doc-mode 1)
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; WORKAROUNDS (with links to upstreams issues)
(require 'ansi-color)

;; https://github.com/haskell/haskell-mode/pull/1608
(setq haskell-compile-color t)
(defun haskell-compilation-filter-hook ()
  "Local `compilation-filter-hook' for `haskell-compilation-mode'."
  (when haskell-compile-ghc-filter-linker-messages
    (delete-matching-lines "^ *Loading package [^ \t\r\n]+ [.]+ linking [.]+ done\\.$"
                           (save-excursion (goto-char compilation-filter-start)
                                           (line-beginning-position))
                           (point)))
  (when haskell-compile-color
    (read-only-mode -1)
    (ansi-color-apply-on-region compilation-filter-start (point-max))
    (read-only-mode 1)))

;; https://github.com/haskell/haskell-mode/pull/1608
(setq haskell-compilation-error-regexp-alist
  `((,(concat
       "^ *\\(?1:[^\t\r\n]+?\\):"
       "\\(?:"
       "\\(?2:[0-9]+\\):\\(?4:[0-9]+\\)\\(?:-\\(?5:[0-9]+\\)\\)?" ;; "121:1" & "12:3-5"
       "\\|"
       "(\\(?2:[0-9]+\\),\\(?4:[0-9]+\\))-(\\(?3:[0-9]+\\),\\(?5:[0-9]+\\))" ;; "(289,5)-(291,36)"
       "\\)"
       ":\\(?6:\n?[ \t]+[Ww]arning:\\)?")
     1 (2 . 3) (4 . 5) (6 . nil))
    ("^    \\(?:Declared at:\\|            \\) \\(?1:[^ \t\r\n]+\\.el\\):\\(?2:[0-9]+\\):\\(?4:[0-9]+\\)$"
     1 2 4 0)

    (".*error, called at \\(.*\\.hs\\):\\([0-9]+\\):\\([0-9]+\\) in .*" 1 2 3 2 1)
    (" +\\(.*\\.hs\\):\\([0-9]+\\):$" 1 2 nil 2 1)
    (" at \\(?1:[^ \t\r\n]+\\):\\(?2:[0-9]+\\):\\(?4:[0-9]+\\)\\(?:-\\(?5:[0-9]+\\)\\)?[)]?$"
     1 2 (4 . 5) 0)))

(provide 'fommil-haskell)

;;; fommil-haskell.el ends here
