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
                 :name "set_directory"
                 :function #'gptel-fommil-set-directory
                 :description "Set the working directory for subsequent tool calls (git, shell, etc)."
                 :args (list '(:name "path"
                                     :type string
                                     :description "Path to the directory, e.g. ~/projects/foo"))
                 :category "context")

                (gptel-make-tool
                 :name "git_log"
                 :function #'gptel-fommil-git-log
                 :description "Run git log in the current project. Pass arguments as a JSON array of strings, e.g. [\"--oneline\", \"-20\", \"--author=sam\"]."
                 :args (list '(:name "arguments"
                                     :type array
                                     :items (:type string)
                                     :description "Arguments to git log as individual strings"))
                 :category "git"
                 :confirm t)

                (gptel-make-tool
                 :name "git_search"
                 :function #'gptel-fommil-git-search
                 :description "Search git history for a string in diffs (pickaxe)."
                 :args (list '(:name "pattern"
                                     :type string
                                     :description "String to search for in diffs")
                             '(:name "path"
                                     :type string
                                     :description "Limit search to this path"
                                     :optional t))
                 :category "git"
                 :confirm t)

                (gptel-make-tool
                 :name "shell_command"
                 :function #'gptel-fommil-shell-command
                 :description "Execute a shell command and return stdout+stderr. Do not use this if another more suitable tool is available."
                 :args (list '(:name "command"
                                     :type string
                                     :description "The shell command to run"))
                 :category "shell"
                 :confirm t)

                ;; tools mostly from https://github.com/karthink/gptel/wiki/Tools-collection
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
                 :function (lambda (filepath)
                             (with-temp-buffer
                               (insert-file-contents (expand-file-name filepath))
                               (buffer-string)))
                 :name "read_file"
                 :description "Read and display the contents of a file"
                 ;; this is one shot, doesn't add to the context
                 :args (list '(:name "filepath"
                                     :type string
                                     :description "Path to the file to read. Supports relative paths and ~."))
                 :confirm t
                 :category "filesystem")


                )))

(defvar gptel-fommil-working-directory nil
  "Override working directory for gptel tool calls.")

(defun gptel-fommil-set-directory (path)
  "Set working directory for gptel tools."
  (let ((expanded (expand-file-name path)))
    (unless (file-directory-p expanded)
      (error "Not a directory: %s" expanded))
    (setq gptel-fommil-working-directory (file-name-as-directory expanded))
    (format "Working directory set to %s" gptel-fommil-working-directory)))

(defun gptel-fommil-git-log (arguments)
  (let ((default-directory (or gptel-fommil-working-directory default-directory)))
    (with-output-to-string
      (apply #'call-process "git" nil standard-output nil "log" (append arguments nil)))))

(defun gptel-fommil-git-search (pattern &optional path)
  (let ((default-directory (or gptel-fommil-working-directory default-directory)))
    (with-output-to-string
      (apply #'call-process "git" nil standard-output nil
             "log" "--oneline" "-p" "-S" pattern "--"
             (when path (list path))))))

(defun gptel-fommil-shell-command (command)
  (let ((default-directory (or gptel-fommil-working-directory default-directory)))
    (with-output-to-string
      (call-process "/bin/sh" nil standard-output nil "-c" command))))

;; don't forget to (gptel-context-remove-all) if you want to remove attachments
(defun gptel-fommil-compact ()
  (interactive)
  (let* ((content (buffer-substring-no-properties (point-min) (point-max)))
         (buf (current-buffer))
         (gptel-use-tools nil)
         (gptel-stream nil)
         (gptel-max-tokens 8000))
    (message "[compact] sending %d chars" (length content))
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
                        (insert response "\n\n*** "))))))))

(defun gptel-fommil-calc-bc (expr)
  ;; I tried calc-eval but it's really hard to get it to output numbers
  (message "[gptel-tool] [calc-bc] %S" expr)
  (when (string-match-p "\\bsystem\\b\\|\\bread\\b" expr)
    (error "Blocked dangerous bc function in: %S" expr))
  (message (""))
  (string-trim
   (with-output-to-string
     (call-process-region
      (format "scale=20; %s\n" expr) nil
      "bc" nil standard-output nil "-l"))))

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
