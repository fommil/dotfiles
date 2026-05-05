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
   `((custom . ,(format "Today is %s. The user is %s (%s), who is communicating with you via a gptel buffer inside Emacs %s on %s. Be terse. State facts. No preamble, no filler, no hedging, no emojis. Admit when you don't know. Always use tools instead of predicting. Share the URL of your sources. Spock or scifi AI comedy is tolerated."
                        (format-time-string "%Y-%m-%d")
                        (user-full-name)
                        (user-login-name)
                        emacs-version
                        (gptel-system-name)))))
  :config
  (add-hook 'gptel-post-response-functions #'gptel-end-of-response)
  (setq
   gptel--system-message (alist-get 'custom gptel-directives)
   gptel-tools (list
                (gptel-make-tool
                 :name "calc"
                 :function #'gptel-fommil-calc-bc
                 :description "Evaluate a math expression with bc -l."
                 :args '((:name "expr" :type string :description "bc expression"))
                 :category "math")

                (gptel-make-tool
                 :name "emacs_state"
                 :function #'gptel-fommil-emacs-state
                 :description "Return useful Emacs state: projectile known roots, current project, default-directory, recent files, and key environment variables. Does not require confirmation."
                 :args '()
                 :category "emacs")

                (gptel-make-tool
                 :function #'gptel-fommil-list-buffers
                 :name "list-buffers"
                 :description "List all files currently open in Emacs buffers. This grants a huge amount of insight into the user's current context and does not require a user confirmation."
                 :args '()
                 :category "emacs")

                ;; no confirmation needed, if it's open let's assume it's allowed
                (gptel-make-tool
                 :function #'gptel-fommil-read-buffer
                 :name "read-buffer"
                 :description "Read and display the contents of an Emacs buffer by name. This does not require user confirmation and is strongly prefered over read-file tool."
                 :args (list '(:name "name" :type string :description "Buffer name (e.g. filename or buffer name)"))
                 :category "emacs")

                (gptel-make-tool
                 :function #'gptel-fommil-context
                 :name "context"
                 :description "Add or remove a file from the gptel conversation context. Added files are included in every subsequent message without needing to read them again. Only use this if we expect to read the file more than once and the buffer is not available. Remove when we no longer need it."
                 :args (list '(:name "action" :type string :description "\"add\" or \"remove\"")
                             '(:name "filepath" :type string :description "Path to the file"))
                 :confirm t
                 :category "emacs")

                (gptel-make-tool
                 :name "set_directory"
                 :function #'gptel-fommil-set-directory
                 :description "Set the working directory for subsequent tool calls."
                 :args (list '(:name "path"
                                     :type string
                                     :description "Path to the directory, e.g. ~/projects/foo"))
                 :category "context")

                (gptel-make-tool
                 :name "git"
                 :function #'gptel-fommil-git
                 :description "Run a git subcommand. Supported: log, grep, search (pickaxe), diff.
Examples:
  subcommand=\"log\", arguments=[\"--oneline\", \"-20\"]
  subcommand=\"grep\", arguments=[\"-n\", \"defun\", \"--\", \"*.el\"]
  subcommand=\"search\", arguments=[\"some-function\", \"--\", \"src/\"]
  subcommand=\"diff\", arguments=[\"HEAD~3\", \"--stat\"]
  subcommand=\"diff\", arguments=[\"--cached\"]"
                 :args (list '(:name "subcommand"
                                     :type string
                                     :description "One of: log, grep, search, diff")
                             '(:name "arguments"
                                     :type array
                                     :items (:type string)
                                     :description "Arguments passed to the git subcommand"))
                 :category "git"
                 :confirm t)

                (gptel-make-tool
                 :name "shell_command"
                 :function #'gptel-fommil-shell-command
                 :description "Execute a shell command and return stdout+stderr. Do not use if another tool can do it, for example prefer list_directory if you only mean to confirm the existence of a file or the git_ commands for git operations."
                 :args (list '(:name "command"
                                     :type string
                                     :description "The shell command to run"))
                 :category "shell"
                 :confirm t)

                ;; from https://github.com/karthink/gptel/wiki/Tools-collection
                (gptel-make-tool
                 :function (lambda (directory)
                             (mapconcat #'identity
                                        (directory-files directory)
                                        "\n"))
                 :name "list_directory"
                 :description "List the contents of a given directory"
                 :args (list '(:name "directory"
                                     :type string
                                     :description "The path to the directory to list"))
                 :category "filesystem")

                (gptel-make-tool
                 :function #'gptel-fommil-read-file
                 :name "read-file"
                 :description "Read and display the contents of a file. Do not use this if the file can be accessed with read-buffer."
                 ;; this is one shot, doesn't add to the context
                 :args (list '(:name "filepath"
                                     :type string
                                     :description "Path to the file to read. Supports relative paths and ~."))
                 :confirm t
                 :category "filesystem")

                )))

(defvar-local gptel-fommil-working-directory nil
  "Override working directory for gptel tool calls.")

(defvar gptel-fommil-tool-max-chars 80000)

(defun gptel-fommil-set-directory (path)
  "Set working directory for gptel tools."
  (let ((expanded (expand-file-name path)))
    (unless (file-directory-p expanded)
      (error "Not a directory: %s" expanded))
    (setq gptel-fommil-working-directory (file-name-as-directory expanded))
    (format "Working directory set to %s" gptel-fommil-working-directory)))

;; show the working directory in the mode-line
(add-hook 'gptel-mode-hook
          (lambda ()
            (setq mode-line-misc-info
                  (append mode-line-misc-info
                          '((:eval (when gptel-fommil-working-directory
                                     (concat " [" (abbreviate-file-name gptel-fommil-working-directory) "]"))))))))

(defun gptel-fommil-list-buffers ()
  (string-join
   (seq-filter (lambda (f) (not (string-match-p "TAGS$" f)))
               (delq nil (mapcar #'buffer-file-name (buffer-list))))
   "\n"))

(defun gptel-fommil-emacs-state ()
  (let ((sections nil))
    (push (format "default-directory: %s" default-directory) sections)
    (push (format "working-directory-override: %s"
                  (or gptel-fommil-working-directory "nil")) sections)
    (when (bound-and-true-p projectile-known-projects)
      (push (format "projectile-known-projects:\n%s"
                    (string-join (seq-take projectile-known-projects 50) "\n"))
            sections))
    (let ((env-vars '("HOME")))
      (push (format "environment:\n%s"
                    (string-join
                     (delq nil (mapcar (lambda (v)
                                         (when-let ((val (getenv v)))
                                           (format "  %s=%s" v val)))
                                       env-vars))
                     "\n"))
            sections))
    (string-join (nreverse sections) "\n\n")))

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

(defun gptel-fommil--truncate (output)
  (if (> (length output) gptel-fommil-tool-max-chars)
      (format "%s\n\n[TRUNCATED at %d chars — use shell_command with head/tail/sed for portions]"
              (substring output 0 gptel-fommil-tool-max-chars)
              gptel-fommil-tool-max-chars)
    output))

(defun gptel-fommil-git (subcommand arguments)
  (gptel-fommil--truncate
   (let ((default-directory (or gptel-fommil-working-directory default-directory))
         (args (append arguments nil)))
     (with-temp-buffer
       (pcase subcommand
         ("log"    (apply #'call-process "git" nil '(t t) nil "log" args))
         ("grep"   (apply #'call-process "git" nil '(t t) nil "grep" "-n" "-I" args))
         ("search" (apply #'call-process "git" nil '(t t) nil
                          "log" "--oneline" "-p" "-S" args))
         ("diff"   (apply #'call-process "git" nil '(t t) nil "diff" args))
         (_        (insert (format "Unknown subcommand: %s. Use log, grep, search, or diff." subcommand))))
       (buffer-string)))))

(defun gptel-fommil-shell-command (command)
  (gptel-fommil--truncate
   (let ((default-directory (or gptel-fommil-working-directory default-directory)))
     (with-temp-buffer
       (call-process "/bin/sh" nil '(t t) nil "-c" command)
       (buffer-string)))))

(defun gptel-fommil-read-buffer (name)
  ;; as a precaution, this only allows reading buffers with a backing file
  ;; so it doesn't expose transient buffers that might leak information.
  (message "[gptel-tool] [read-buffer] %S" name)
  (gptel-fommil--truncate
   (if-let ((buf (or (get-buffer name)
                     (find-buffer-visiting name))))
       (if (buffer-file-name buf)
           (with-current-buffer buf
             (buffer-substring-no-properties (point-min) (point-max)))
         (format "Buffer %s has no backing file" name))
     (format "No buffer named %s" name))))

(defun gptel-fommil-read-file (filepath)
  (gptel-fommil--truncate
   (let* ((file (expand-file-name filepath))
          (attrs (file-attributes file)))
     (unless attrs
       (error "File not found: %s" file))
     (with-temp-buffer
       (insert-file-contents file)
       (buffer-string)))))

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

;; don't forget to (gptel-context-remove-all) if you want to remove attachments
(defun gptel-fommil-compact ()
  (interactive)
  (let* ((context-alist (gptel-context--alist))
         (context-files (mapcar #'car context-alist))
         (context-info (when context-files
                         (format "\n\nContext files that were attached (now removed):\n%s"
                                 (string-join
                                  (mapcar (lambda (f) (format "- %s" f)) context-files)
                                  "\n"))))
         (content (buffer-substring-no-properties (point-min) (point-max)))
         (buf (current-buffer))
         (gptel-use-tools nil)
         (gptel-stream nil)
         (gptel-max-tokens 8000))
    (gptel-context-remove-all)
    (message "[compact] sending %d chars, removed %d context files"
             (length content) (length context-files))
    (gptel-request
        content
      :buffer buf
      :system "Summarize this conversation tersely. Preserve decisions and open questions. Drop pleasantries and dead ends. Output the summary only."
      :callback (lambda (response info)
                  (message "[compact] cb: %S" (if (stringp response) (length response) response))
                  (when (stringp response)
                    (with-current-buffer (plist-get info :buffer)
                      (let ((inhibit-read-only t))
                        (erase-buffer)
                        (insert response)
                        (when context-info (insert context-info))
                        (insert "\n\n*** "))))))))

(use-package mcp
  :ensure t
  :after gptel
  :config
  (setq
   mcp-hub-servers (list
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
   (dotimes (i 10) (run-with-timer (1+ i) nil #'gptel-mcp-connect))

   ))

;;(setq gptel-log-level 'debug)

(provide 'fommil-llm)
;;; fommil-llm.el ends here
