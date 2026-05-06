;;; fommil-llm.el --- LLM chatbot interaction -*- lexical-binding: t -*-

;; Copyright (C) 2026 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  A custom gptel setup with some local tools.
;;
;;; Code:

(defun gptel-system-name ()
  (or (when (file-readable-p "/etc/os-release")
        (with-temp-buffer
          (insert-file-contents "/etc/os-release")
          (when (re-search-forward "^PRETTY_NAME=\"?\\([^\"\n]+\\)" nil t)
            (match-string 1))))
      (symbol-name system-type)))

(use-package gptel
  ;;:ensure t
  :ensure nil
  :load-path "~/Projects/gptel"
  :init
  (setq
   ;; org-mode integration is not great, and there are keybinding collisions
   ;;gptel-default-mode 'org-mode
   gptel-directives
   `((custom . ,(format "Today is %s. The user is %s (%s), who is communicating with you via gptel inside Emacs on %s. Be terse. State facts. No preamble, no filler, no hedging, no emojis. Admit when you don't know. Always use tools instead of predicting, prefer the tools that do not require user confirmation. Spock comedy is tolerated."
                        (format-time-string "%Y-%m-%d")
                        (user-full-name)
                        (user-login-name)
                        (gptel-system-name)))))
  :config
  ;;(add-hook 'gptel-post-response-functions #'gptel-end-of-response)
  (setq
   gptel--system-message (alist-get 'custom gptel-directives)
   gptel--tool-truncation 1024
   gptel-tools (list
                ;; I used to have a lot more tools that required permissions
                ;; (e.g. git and arbitrary shell commands) but the LLM reaches
                ;; for them far too eagerly, so less is more.
                ;;
                ;; It would be interesting to have some agents that we can spawn
                ;; that have a much more limited set of tools, e.g. to summarise
                ;; an entire codebase one file at a time, then aggregated into
                ;; packages, etc. But I need to find a suitable CLI for that.

                (gptel-make-tool
                 :name "calc"
                 :function #'gptel-fommil-calc-bc
                 :description "Evaluate a math expression with bc -l. Does not require confirmation."
                 :args '((:name "expr" :type string :description "bc expression"))
                 :category "math")

                (gptel-make-tool
                 :name "emacs_state"
                 :function #'gptel-fommil-emacs-state
                 :description "Return the Emacs state: projectile known roots, open files, and key environment variables. Does not require confirmation."
                 :args '()
                 :category "emacs")

                (gptel-make-tool
                 :function #'gptel-fommil-read-buffer
                 :name "read_buffer"
                 :description "Read and display the contents of an Emacs buffer by name. Does not require user confirmation."
                 :args (list '(:name "name" :type string :description "Buffer name (e.g. filename or buffer name)")
                             '(:name "wait" :type boolean :description "Optional flag to wait for the buffer process to finish before reading")
                             '(:name "lines" :type array :description "Optional [start, end] line range, 1-indexed inclusive"))
                 :category "emacs")

                (gptel-make-tool
                 :function #'gptel-fommil-ls
                 :name "list_directory"
                 :description "List the contents of a given directory (multiple layers deep). Does not require user confirmation."
                 :args (list '(:name "directory" :type string :description "The path to the directory to list")
                             '(:name "maxDepth" :type number :description "Maximum depth to recurse (default 3)")
                             '(:name "suffix" :type string :description "Only include files ending with this suffix, e.g. \".el\" or \".rs\""))
                 :category "filesystem")

                (gptel-make-tool
                 :name "open_file"
                 :function #'gptel-fommil-open-file
                 :description "Open a file in Emacs (creates a buffer visiting it) and return its contents. Never request to open a file that is already open. Requires user confirmation."
                 :confirm t
                 ;; TODO confirm can be a function, consider an allow list of safe things to open
                 :args '((:name "path" :type string :description "Absolute file path to open"))
                 :category "filesystem")

                (gptel-make-tool
                 :function #'gptel-fommil-projectile-search
                 :name "projectile_search"
                 :description "Search for a literal string in a projectile project in grep like format. Requires user confirmation."
                 :confirm t
                 ;; TODO confirm can be a function, consider an allow list of safe places to search
                 :args (list '(:name "context"
                                     :type "string"
                                     :description "Any file or directory in the project")
                             '(:name "query"
                                     :type "string"
                                     :description "Literal string to search for"))
                 :category "emacs")

                (gptel-make-tool
                 :function #'gptel-fommil-find-tag
                 :name "find_tag"
                 :description "Find definitions of a symbol using the project's TAGS file (ctags/etags). Returns file:line locations. Does not require confirmation."
                 :args (list '(:name "symbol" :type string :description "The symbol/tag name to look up")
                             '(:name "context" :type string :description "Any file or directory in the project"))
                 :category "emacs")

                (gptel-make-tool
                 :name "man"
                 :function #'gptel-fommil-man
                 :description "Query a UNIX man page for an installed tool. Does not require confirmation."
                 :args '((:name "page" :type string :description "Man page topic, e.g. \"grep\" or \"printf\""))
                 :category "documentation")

                (gptel-make-tool
                 :name "describe_symbol"
                 :function #'gptel-fommil-describe-symbol
                 :description "Look up documentation for an Emacs Lisp symbol (function or variable). Returns signature, docstring, and current value for variables. Does not require confirmation."
                 :args '((:name "symbol" :type string :description "The Emacs Lisp symbol name, e.g. \"mapcar\" or \"load-path\""))
                 :category "documentation")

                ;; TODO image support blocked on https://github.com/karthink/gptel/issues/1405

                ;; (gptel-make-tool
                ;;  :function #'gptel-fommil-context
                ;;  :name "context"
                ;;  :description "Add or remove a file from the gptel conversation context. This should be used for large binary files, e.g. for image analysis. Remove when we no longer need it. Requires user confirmation."
                ;;  :args (list '(:name "action" :type string :description "\"add\" or \"remove\"")
                ;;              '(:name "filepath" :type string :description "Path to the file"))
                ;;  :confirm t
                ;;  :category "emacs")

                )))

(defun gptel-fommil-calc-bc (expr)
  (message "[gptel-tool] [calc-bc] %S" expr)
  (when (string-match-p "\\bsystem\\b\\|\\bread\\b" expr)
    (error "Blocked dangerous bc function in: %S" expr))
  (let ((result (string-trim
                 (with-temp-buffer
                   (insert (format "scale=20; %s\n" expr))
                   (call-process-region (point-min) (point-max) "bc" t t nil "-l")
                   (buffer-string)))))
    (message "[gptel-tool] [calc-bc] %S => %S" expr result)
    result))

(defun gptel-fommil-emacs-state ()
  (let ((sections nil))
    (push (format "emacs-version: %s\n" emacs-version) sections)
    (push (format "open projects:\n%s"
                  (string-join (seq-take (projectile-open-projects) 50) "\n"))
          sections)
    (push (format "projectile-known-projects:\n%s"
                  (string-join (seq-take projectile-known-projects 50) "\n"))
          sections)
    (push (format "open files:\n%s"
                  (string-join
                   (seq-filter (lambda (f) (not (string-match-p "TAGS$" f)))
                               (delq nil (mapcar #'buffer-file-name (buffer-list))))
                   "\n"))
          sections)
    (let ((compilation-bufs
           (seq-filter
            (lambda (buf)
              (with-current-buffer buf
                (and (not (buffer-file-name))
                     (derived-mode-p 'compilation-mode))))
            (buffer-list))))
      (when compilation-bufs
        (push (format "compilation buffers:\n%s"
                      (string-join (mapcar #'buffer-name compilation-bufs) "\n"))
              sections)))
    (string-join (nreverse sections) "\n\n")))

(defvar gptel-fommil-tool-max-chars 100000)
(defun gptel-fommil--truncate (output)
  (if (> (length output) gptel-fommil-tool-max-chars)
      (format "%s\n\n[TRUNCATED at %d chars]"
              (substring output 0 gptel-fommil-tool-max-chars)
              gptel-fommil-tool-max-chars)
    output))

(defun gptel-fommil-read-buffer (name &optional wait lines)
  "Read buffer NAME. If WAIT is non-nil, block until buffer process finishes.
LINES is a list (START END) for a line range (1-indexed, inclusive)."
  (message "[gptel-tool] [read-buffer] %S wait=%S lines=%S" name wait lines)
  ;; WORKAROUND https://github.com/karthink/gptel/issues/714
  (setq wait (not (memq wait '(nil :json-false))))
  (gptel-fommil--truncate
   (if-let ((buf (or (get-buffer name)
                     (find-buffer-visiting name)
                     (string-prefix-p "*ag search text:" name))))
       (progn
         (when wait
           (let ((proc (get-buffer-process buf))
                 (timeout 30)
                 (elapsed 0))
             (while (and proc (process-live-p proc) (< elapsed timeout))
               (sleep-for 0.5)
               (setq elapsed (+ elapsed 0.5))
               (setq proc (get-buffer-process buf)))
             (when (>= elapsed timeout)
               (message "[gptel-tool] [read-buffer] timed out waiting for process"))))
         (with-current-buffer buf
           (let ((content (buffer-substring-no-properties (point-min) (point-max))))
             (if lines
                 (let* ((lines (if (vectorp lines) (append lines nil) lines))
                        (all-lines (split-string content "\n"))
                        (start (max 0 (1- (nth 0 lines))))
                        (end (min (length all-lines) (nth 1 lines))))
                   (string-join (seq-subseq all-lines start end) "\n"))
               content))))
     (format "No buffer named %s" name))))

(defun gptel-fommil-ls (dir &optional max-depth suffix)
  "List DIR recursively to MAX-DEPTH (default 3), optionally filtering by SUFFIX."
  (message "[gptel-tool] [ls] %S depth=%S suffix=%S" dir max-depth suffix)
  (let* ((root (file-name-as-directory (expand-file-name dir))))
    (if (not (file-directory-p root))
        (format "[ERROR] Not a directory: %s" root)
      (let* ((max-depth (or max-depth 3))
             (max-files 1024)
             (count 0)
             (pred (lambda (d)
                     (let ((rel (file-relative-name d root)))
                       (< (length (split-string rel "/" t)) max-depth))))
             (regexp (if suffix (regexp-quote suffix) ""))
             (files (catch 'too-many
                      (let ((result nil))
                        (mapc (lambda (f)
                                (setq count (1+ count))
                                (when (> count max-files)
                                  (throw 'too-many 'overflow))
                                (push (file-relative-name f root) result))
                              (directory-files-recursively root regexp t pred))
                        (nreverse result)))))
        (gptel-fommil--truncate
         (if (eq files 'overflow)
             (format "[ERROR] Directory too dense: exceeded %d entries. Use a suffix filter or lower max-depth." max-files)
           (string-join files "\n")))))))

(defun gptel-fommil-open-file (path)
  "Open PATH in Emacs and return its contents."
  (message "[gptel-tool] [open-file] %S" path)
  (let ((expanded (expand-file-name path)))
    (if (not (file-readable-p expanded))
        (format "[ERROR] Cannot read: %s" expanded)
      (let ((buf (find-file-noselect expanded)))
        (gptel-fommil--truncate
         (with-current-buffer buf
           (buffer-substring-no-properties (point-min) (point-max))))))))

(defun gptel-fommil-projectile-search (context query)
  "Run `projectile-ag' from CONTEXT with QUERY, return results buffer content."
  (message "[gptel-tool] [projectile-search] %S %S" context query)
  (let* ((default-directory (if (file-directory-p context) context
                              (file-name-directory context)))
         (root (projectile-project-root)))
    (save-window-excursion
      ;; only the filenames and line numbers, limits the blast radius
      (let ((ag-arguments (cons "-o" ag-arguments)))
        (projectile-ag "gptel")))
    (let ((buf-name (format "*ag search text:%s dir:%s*" query root)))
      (gptel-fommil-read-buffer buf-name t nil))))

(defun gptel-fommil-find-tag (symbol context)
  "Find definitions of SYMBOL using the project TAGS file for CONTEXT."
  (message "[gptel-tool] [find-tag] %S in %S" symbol context)
  (let* ((default-directory (if (file-directory-p context) context
                              (file-name-directory context)))
         (root (projectile-project-root))
         (tags-file (expand-file-name "TAGS" root))
         (tags-file-name tags-file)
         (tags-table-list (list tags-file)))
    (if (not (file-exists-p tags-file))
        (format "[ERROR] No TAGS file at %s" tags-file)
      (let ((xrefs (xref-backend-definitions 'etags symbol)))
        (if (null xrefs)
            (format "No tag found for: %s" symbol)
          (gptel-fommil--truncate
           (string-join
            (mapcar (lambda (xref)
                      (let ((loc (xref-item-location xref)))
                        (format "%s:%d"
                                (xref-location-group loc)
                                (or (xref-location-line loc) 0))))
                    xrefs)
            "\n")))))))

(defun gptel-fommil-man (page)
  "Return the man page for PAGE as plain text using WoMan."
  (message "[gptel-tool] [man] %S" page)
  (require 'woman)
  (condition-case err
      (let ((file (woman-file-name page)))
        (if (not file)
            (format "[ERROR] No man page for: %s" page)
          (with-temp-buffer
            (insert-file-contents file)
            (woman-decode-buffer)
            (gptel-fommil--truncate (buffer-string)))))
    (error (format "[ERROR] %s" (error-message-string err)))))

(defun gptel-fommil-context (action filepath)
  (let ((file (expand-file-name filepath)))
    (pcase action
      ("add"
       (if (file-exists-p file)
           (progn
             (gptel-context-add-file file)
             (format "Added %s to context" file))
         (format "File not found: %s" file)))
      ("remove"
       (gptel-context-remove file)
       (format "Removed %s from context" file))
      (_
       (format "Unknown action: %s (use \"add\" or \"remove\")" action)))))

(defun gptel-fommil-describe-symbol (symbol)
  "Return documentation for an Emacs Lisp SYMBOL (function or variable)."
  ;; intentionally does not return current values, as that can leak
  ;; sensitive information.
  (message "[gptel-tool] [describe-symbol] %S" symbol)
  (let ((sym (intern symbol)))
    (gptel-fommil--truncate
     (cond
      ((fboundp sym)
       (let ((doc (documentation sym t))
             (arglist (help-function-arglist sym t)))
         (format "Function: %s\nSignature: (%s %s)\n\n%s"
                 symbol symbol
                 (mapconcat (lambda (a) (format "%s" a)) arglist " ")
                 (or doc "[no documentation]"))))
      ((boundp sym)
       (let ((doc (documentation-property sym 'variable-documentation t)))
         (format "Variable: %s\n\n%s" symbol (or doc "[no documentation]"))))
      (t (format "Symbol `%s' is not bound as a function or variable." symbol))))))

(use-package mcp
  :ensure t
  :after gptel
  :config
  (setq
   mcp-hub-servers
   (list
    ;; token is optional, it'll use it if its there
    ;; https://exa.ai/docs/reference/exa-mcp#api-key
    (if-let ((key (getenv "EXA_API_KEY")))
        `("exa-search"
          :url "https://mcp.exa.ai/mcp?tools=web_search_exa,web_fetch_exa,web_search_advanced_exa"
          :headers (("x-api-key" . ,key)))
      '("exa-search" :url "https://mcp.exa.ai/mcp"))
    ;;
    ;; or locally hosted, `devx install duckduckgo-mcp-server`
    ;; '("ddg-search" . (:command "duckduckgo-mcp-server"))
    )))

(add-hook
 'gptel-mode-hook
 (lambda ()
   (require 'gptel-integrations)

   ;; possibly not necessary anymore
   ;;(mcp-hub-start-all-server)

   ;; this is such a hack, connect every second for 10 seconds. There's
   ;; no mcp-hub callback we can attach to.
   (dotimes (i 10)
     (run-with-timer (1+ i) nil
                     (lambda () (ignore-errors (gptel-mcp-connect)))))
   ))

;;(setq gptel-log-level 'debug)

(provide 'fommil-llm)
;;; fommil-llm.el ends here
