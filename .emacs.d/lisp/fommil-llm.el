;;; fommil-llm.el --- LLM chatbot interaction -*- lexical-binding: t -*-

;; Copyright (C) 2026 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;; This customises the gtpel LLM chatbot interface with a suite of tools that
;; assist without getting in the way. It is important that the blast radius of
;; all tools is minimised, any mutations or access to potentially sensitive data
;; requires user consent (there is an allow list of file suffixes that can
;; bypass user auth). As much as possible, everything is done in Emacs for
;; transparency (e.g. the LLM can only open files in Emacs, and cannot close
;; them). The LLM cannot run arbitrary code and cannot create or edit project
;; files.
;;
;; The biggest compromise is web search and fetch, which is provided through an
;; MCP (exa or ddg).
;;
;;
;; Some thoughts on tooling choice: I used to have a lot more tools that
;; required permissions (e.g. git and arbitrary shell commands) but the LLM
;; reaches for them far too eagerly, so less is more.
;;
;; It would be interesting to have some agents that we can spawn that have a
;; much more limited set of tools, e.g. to summarise an entire codebase one file
;; at a time, then aggregated into packages, etc. But I need to find a suitable
;; CLI for that. It is not too hard to write standalone / one-shot scripts that
;; can use the upstream LLM API (e.g. bedrock) directly.

;; TODO image support blocked on https://github.com/karthink/gptel/issues/1405

;;; Code:

(defvar gptel-fommil-safe-suffixes
  '(".el" ".scala" ".sbt" ".java" ".rs" ".py" ".hs" ".cabal"
    ".c" ".h" ".cpp" ".hpp" ".go"
    ".md" ".txt" ".org"
    ".diff" ".patch"
    ".sql"
    "Makefile"
    ".json" ".yaml" ".yml" ".xml" ".proto"
    ".sh"
    ".toml" ".conf" ".cfg" ".ini" ".properties"
    ".html" ".css" ".js"))

;; TODO improve this calculator, prefer not to shell out. Emacs calc isn't great
;; but maybe we can make it work or find an alternative impl
(defun gptel-fommil-calc-bc ()
  (gptel-make-tool
   :name "calc"
   :description "Evaluate a math expression with bc -l."
   :args '((:name "expr" :type string :description "bc expression"))
   :category "math"
   :function
   (lambda (expr)
     ;;(message "[gptel-tool] [calc-bc] %S" expr)
     (when (string-match-p "\\bsystem\\b\\|\\bread\\b" expr)
       (error "Blocked dangerous bc function in: %S" expr))
     (let ((result (string-trim
                    (with-temp-buffer
                      (insert (format "scale=20; %s\n" expr))
                      (call-process-region (point-min) (point-max) "bc" t t nil "-l")
                      (buffer-string)))))
       ;;(message "[gptel-tool] [calc-bc] %S => %S" expr result)
       result))))

(defun gptel-fommil-emacs-state ()
  (gptel-make-tool
   :name "emacs_state"
   :description "Return the Emacs state: projectile known roots, open files, and key environment variables."
   :args '()
   :category "emacs"
   :function
   (lambda ()
     (let ((sections nil))
       (push (format "system-type: %s\n" (symbol-name system-type)) sections)
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
       (string-join (nreverse sections) "\n\n")))))

(defvar gptel-fommil-tool-max-chars 100000)
(defun gptel-fommil--truncate (output)
  (if (> (length output) gptel-fommil-tool-max-chars)
      (format "%s\n\n[TRUNCATED at %d chars]"
              (substring output 0 gptel-fommil-tool-max-chars)
              gptel-fommil-tool-max-chars)
    output))

(defun gptel-fommil-read-buffer ()
  (gptel-make-tool
   :name "read_buffer"
   :description "Read and display the contents of an Emacs buffer by name."
   :args (list '(:name "name" :type string :description "Buffer name (e.g. filename or buffer name)")
               '(:name "wait" :type boolean :description "Optional flag to wait for the buffer process to finish before reading")
               '(:name "lines" :type array :description "Optional [start, end] line range, 1-indexed inclusive"))
   :category "emacs"
   :function #'gptel-fommil--read-buffer))

(defun gptel-fommil--read-buffer (name &optional wait lines)
  ;;(message "[gptel-tool] [read-buffer] %S wait=%S lines=%S" name wait lines)
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

(defun gptel-fommil-ls ()
  (gptel-make-tool
   :name "list_directory"
   :description "List the contents of a given directory (multiple layers deep)."
   :args (list '(:name "directory" :type string :description "The path to the directory to list")
               '(:name "maxDepth" :type number :description "Maximum depth to recurse (default 3)")
               '(:name "suffix" :type string :description "Only include files ending with this suffix, e.g. \".el\" or \".rs\""))
   :category "filesystem"
   :function
   (lambda (dir &optional max-depth suffix)
     "List DIR recursively to MAX-DEPTH (default 3), optionally filtering by SUFFIX."
     ;;(message "[gptel-tool] [ls] %S depth=%S suffix=%S" dir max-depth suffix)
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
              (string-join files "\n")))))))))

(defun gptel-fommil-open-file ()
  (gptel-make-tool
   :name "open_file"
   :description "Open a file in Emacs (creates a buffer visiting it) and return its contents. Never use this if the file is already opened in a buffer. Requires user confirmation."
   :args '((:name "path" :type string :description "Absolute file path to open")
           (:name "lines" :type array :description "Optional [start, end] line range, 1-indexed inclusive"))
   :category "filesystem"

   :confirm
   (lambda (path &optional _lines)
     (message "[gptel-fommil-open-file-confirm-p] %S" path)
     (let ((expanded (expand-file-name path))
           (suffix (file-name-extension path t)))
       (not (or (find-buffer-visiting expanded)
                (member suffix gptel-fommil-safe-suffixes)))))

   :function
   (lambda (path &optional lines)
     ;;(message "[gptel-tool] [open-file] %S" path lines)
     (let ((expanded (expand-file-name path)))
       (if (not (file-readable-p expanded))
           (format "[ERROR] Cannot read: %s" expanded)
         (let ((buf (find-file-noselect expanded)))
           (gptel-fommil--read-buffer (buffer-name buf) nil lines)))))))

(defun gptel-fommil-projectile-search ()
  (gptel-make-tool
   :name "projectile_search"
   :description "Search for a literal string in a projectile project in grep like format. Requires user confirmation."

   :args (list '(:name "context"
                       :type "string"
                       :description "Any file or directory in the project")
               '(:name "query"
                       :type "string"
                       :description "Literal string to search for"))
   :category "emacs"

   :confirm
   (lambda (context _query)
     ;;(message "[gptel projectile_search_confirm] %s" context)
     (let* ((default-directory (if (file-directory-p context) context
                                 (file-name-directory context)))
            (root (projectile-project-root)))
       ;;(message "dir root %s %s" default-directory root)
       (not (and root
                 (file-directory-p (expand-file-name ".git" root))))))

   :function
   (lambda (context query)
     (require 'ag)
     ;;(message "[gptel-tool] [projectile-search] %S %S" context query)
     (let* ((default-directory (if (file-directory-p context) context
                                 (file-name-directory context)))
            (root (projectile-project-root))
            (ag-arguments (cons "-o" ag-arguments)))
       (cl-letf (((symbol-function 'display-buffer) #'ignore))
         (projectile-ag query))
       (let* ((buf-name (ag/buffer-name query root nil))
              (result (gptel-fommil--read-buffer buf-name t nil)))
         (kill-buffer buf-name)
         result)))))

(defun gptel-fommil-find-tag ()
  (gptel-make-tool
   :name "find_tag"
   :description "Find definitions of a symbol using the project's TAGS file (ctags/etags). Returns file:line locations."
   :args (list '(:name "symbol" :type string :description "The symbol/tag name to look up")
               '(:name "context" :type string :description "Any file or directory in the project"))
   :category "emacs"
   :function
   (lambda (symbol context)
     ;;(message "[gptel-tool] [find-tag] %S in %S" symbol context)
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
               "\n")))))))))

(defun gptel-fommil-man ()
  (gptel-make-tool
   :name "man"
   :description "Query a UNIX man page for an installed tool."
   :args '((:name "page" :type string :description "Man page topic, e.g. \"grep\" or \"printf\""))
   :category "documentation"
   :function
   (lambda (page)
     ;;(message "[gptel-tool] [man] %S" page)
     (require 'woman)
     (condition-case err
         (let ((file (woman-file-name page)))
           (if (not file)
               (format "[ERROR] No man page for: %s" page)
             (with-temp-buffer
               (insert-file-contents file)
               (woman-decode-buffer)
               (gptel-fommil--truncate (buffer-string)))))
       (error (format "[ERROR] %s" (error-message-string err)))))))

(defun gptel-fommil-describe-symbol ()
  (gptel-make-tool
   :name "describe_symbol"
   :description "Look up documentation for an Emacs Lisp symbol (function or variable). Returns signature, docstring, and current value for variables."
   :args '((:name "symbol" :type string :description "The Emacs Lisp symbol name, e.g. \"mapcar\" or \"load-path\""))
   :category "documentation"
   :function
   (lambda (symbol)
     "Return documentation for an Emacs Lisp SYMBOL (function or variable)."
     ;; intentionally does not return current values, as that can leak
     ;; sensitive information.
     ;;(message "[gptel-tool] [describe-symbol] %S" symbol)
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
         (t (format "Symbol `%s' is not bound as a function or variable." symbol))))))))

(defvar gptel-fommil-memory-file
  (expand-file-name "llm-memory" "~/.emacs.d/"))

(defun gptel-fommil-memory ()
  (gptel-make-tool
   :name "memory"
   :description "Persistent key-value memory. Call with no arguments to read all entries. Values should include context about why the information matters."
   :args '((:name "key" :type string :description "Unique identifier for this memory entry" :optional t)
           (:name "value" :type string :description "Value to store. Empty string deletes the entry." :optional t))
   :category "memory"
   :function
   (lambda (&optional key value)
     (let ((alist (if (file-exists-p gptel-fommil-memory-file)
                      (with-temp-buffer
                        (insert-file-contents gptel-fommil-memory-file)
                        (read (buffer-string)))
                    nil)))
       (cond
        ((null key)
         (if alist
             (mapconcat (lambda (pair)
                          (format "%s: %s" (car pair) (cdr pair)))
                        alist "\n")
           "[empty]"))
        ((null value)
         (let ((entry (assoc key alist)))
           (if entry
               (format "%s: %s" (car entry) (cdr entry))
             (format "[not found] %s" key))))
        (t
         (let* ((filtered (assoc-delete-all key alist))
                (new-alist (if (string-empty-p value)
                               filtered
                             (append filtered (list (cons key value))))))
           (with-temp-file gptel-fommil-memory-file
             (let ((print-level nil)
                   (print-length nil))
               (pp new-alist (current-buffer))))
           (if (string-empty-p value)
               (format "Deleted: %s" key)
             (format "Stored: %s: %s" key value)))))))))

(defun gptel-fommil-diff-propose ()
  (gptel-make-tool
   :name "diff_apply"
   :description "Propose changes to a file via a list of search-and-replace operations. Each operation finds the first occurrence of SEARCH in the (progressively modified) file content and replaces it with REPLACE. Operations are applied in order. This is best for changes that span more than 10 lines."
   :args '((:name "path"
                  :type string
                  :description "Absolute path of the target file")
           (:name "edits"
                  :type array
                  :description "Ordered list of search-and-replace operations"
                  :items (:type object
                                :required ["search" "replace"]
                                :properties
                                (:search (:type string
                                                :description "Exact text to find (first occurrence)")
                                         :replace (:type string
                                                         :description "Replacement text")))))
   :category "filesystem"
   :function
   (lambda (path edits)
     ;;(message "[gpt-tool] [diff-propose] %S %S" path edits)
     (let ((expanded (expand-file-name path)))
       (if (not (file-readable-p expanded))
           (format "[ERROR] Target file not readable: %s" expanded)
         (let* ((original (with-temp-buffer
                            (insert-file-contents expanded)
                            (buffer-string)))
                (content original)
                (err nil))
           (catch 'abort
             (seq-do-indexed
              (lambda (edit idx)
                (let* ((search (plist-get edit :search))
                       (replace (plist-get edit :replace))
                       (pos (string-search search content)))
                  (if (not pos)
                      (progn
                        (setq err (format "[ERROR] Edit %d: search text not found. Show proposed changes inline instead." idx))
                        (throw 'abort nil))
                    (setq content (concat (substring content 0 pos)
                                          replace
                                          (substring content (+ pos (length search))))))))
              edits))
           (if err err
             (if (string= original content)
                 "[NO-OP] Edits produced no change."
               (let* ((tmp-dir (make-temp-file "gptel-diff-" t))
                      (fname (file-name-nondirectory expanded))
                      (tmp-orig (expand-file-name (concat fname ".orig") tmp-dir))
                      (tmp-new (expand-file-name (concat fname ".new") tmp-dir))
                      (tmp-patch (make-temp-file "gptel-patch-" nil ".diff")))
                 (with-temp-file tmp-orig (insert original))
                 (with-temp-file tmp-new (insert content))
                 (with-temp-file tmp-patch
                   (call-process "diff" nil t nil "-u"
                                 "--label" fname
                                 "--label" fname
                                 tmp-orig tmp-new))
                 (delete-file tmp-orig)
                 (delete-file tmp-new)
                 (delete-directory tmp-dir)
                 (let ((buf (find-file-noselect tmp-patch)))
                   (with-current-buffer buf
                     (diff-mode)
                     (setq-local default-directory (file-name-directory expanded)))
                   (display-buffer buf)
                   (format "Diff opened in diff-mode. Apply hunks with C-c C-a.")))))))))))

(use-package gptel
  ;;:ensure t
  :ensure nil
  :load-path "~/Projects/gptel"
  :config
  ;;(add-hook 'gptel-post-response-functions #'gptel-end-of-response)
  (setq
   ;; org-mode integration is not great, and there are keybinding collisions
   ;;gptel-default-mode 'org-mode
   gptel-directives
   `((custom . ,(format "Today is %s. The user is %s (%s), who is communicating with you via gptel inside Emacs. Be terse. State facts. No preamble. No filler. No hedging. No emojis. Cite your sources. Admit when you don't know. Always use tools instead of predicting. Prefer tools that do not require user confirmation. The user values free and open source software, security and privacy. The user is an experienced developer, your goal is to assist them and to offer code only when requested to do so. Speak like Spock or Data from Star Trek."
                        (format-time-string "%Y-%m-%d")
                        (user-full-name)
                        (user-login-name))))
   gptel--system-message (alist-get 'custom gptel-directives)
   gptel--tool-truncation 1024 ;; requires https://github.com/karthink/gptel/pull/1401
   gptel-tools (list
                (gptel-fommil-calc-bc)
                (gptel-fommil-emacs-state)
                (gptel-fommil-read-buffer)
                (gptel-fommil-ls)
                (gptel-fommil-open-file)
                (gptel-fommil-projectile-search)
                (gptel-fommil-find-tag)
                (gptel-fommil-man)
                (gptel-fommil-describe-symbol)
                (gptel-fommil-memory)
                (gptel-fommil-diff-propose)
                )))

(use-package mcp
  :ensure t
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
   ;;
   ;; FIXME use the callback as per https://github.com/lizqwerscott/mcp.el
   (dotimes (i 10)
     (run-with-timer (1+ i) nil
                     (lambda () (ignore-errors (gptel-mcp-connect)))))
   ))

;;(setq gptel-log-level 'debug)

(provide 'fommil-llm)
;;; fommil-llm.el ends here
