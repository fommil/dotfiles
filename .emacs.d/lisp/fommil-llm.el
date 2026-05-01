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
  :ensure t
  :init
  (setq
   gptel-directives
   `((default . ,(format "Today is %s. The user is %s (%s), who is communicating with you via a gptel buffer inside Emacs %s on %s. Be terse. State facts. No preamble, no filler, no hedging, no emojis. Admit when you don't know. Always use tools instead of predicting. Share the URL of your sources. Spock or scifi AI comedy is tolerated."
                         (format-time-string "%Y-%m-%d")
                         (user-full-name)
                         (user-login-name)
                         emacs-version
                         (gptel-system-name)))))
  :config
  (add-hook 'gptel-post-response-functions #'gptel-end-of-response)
  (setq
   ;; buggy that we need to set this again tbqh
   gptel--system-message (alist-get 'default gptel-directives)
   gptel-tools (list
                (gptel-make-tool
                 :name "calc"
                 :function #'gptel-calc-bc
                 :description "Evaluate a math expression with bc -l."
                 :args '((:name "expr" :type string :description "bc expression"))
                 :category "math")
                ;; these are how we'd do local search/fetch with full control,
                ;; but later in the file we use an MCP API so these are
                ;; redundant.
                ;;
                ;; (gptel-make-tool
                ;;  :name "web_search"
                ;;  :function #'gptel-web-search
                ;;  :description "Search the web. Returns top 10 result titles and URLs."
                ;;  :args '((:name "query" :type string :description "Search query"))
                ;;  :category "web")
                ;; (gptel-make-tool
                ;;  :name "web_fetch"
                ;;  :function #'gptel-web-fetch
                ;;  :description "Fetch a URL and return its text content (HTML stripped if pandoc available). Truncated at 50KB."
                ;;  :args '((:name "url" :type string :description "URL to fetch"))
                ;;  :category "web")
                )))

;; don't forget to (gptel-context-remove-all) if you want to remove attachments
(defun gptel-compact-buffer ()
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

(defun gptel-calc-bc (expr)
  ;; I tried calc-eval but it's really hard to get it to output numbers
  (message "[gptel-tool] [calc-bc] %S" expr)
  (string-trim
   (shell-command-to-string
    (format "echo 'scale=20; %s' | bc -l"
            (replace-regexp-in-string "'" "" expr)))))

(defun gptel-web-search (query)
  (message "[gptel-tool] [web-search] %S" query)
  (with-temp-buffer
    (let ((url (format "https://html.duckduckgo.com/html/?q=%s"
                       (url-hexify-string query))))
      (call-process "curl" nil t nil "-sL" "-A" "Mozilla/5.0" url))
    ;; crude extraction: titles + snippets
    (let (results)
      (goto-char (point-min))
      (while (re-search-forward
              "result__a\"[^>]*href=\"\\([^\"]+\\)\"[^>]*>\\([^<]+\\)</a>"
              nil t)
        (push (format "%s\n  %s" (match-string 2) (match-string 1)) results))
      (mapconcat #'identity (nreverse (seq-take (nreverse results) 10)) "\n\n"))))

(defun gptel-web-fetch (url)
  (with-temp-buffer
    (call-process "lynx" nil t nil "-dump" "-nolist" "-width=120" url)
    (buffer-substring-no-properties
     (point-min)
     (min (point-max) (+ (point-min) 50000)))))

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
                    ;; ("ddg-search" . (:command "duckduckgo-mcp-server"))
                    )))

(add-hook
 'gptel-mode-hook
 (lambda ()
   (require 'gptel-integrations)

   (mcp-hub-start-all-server)

   ;; this is such a hack, connect every second for 10 seconds. There's
   ;; no mcp-hub callback we can attach to.
   (dotimes (i 10) (run-with-timer (1+ i) nil #'gptel-mcp-connect))

   ))

;;(setq gptel-log-level 'debug)

(provide 'fommil-llm)
;;; fommil-llm.el ends here
