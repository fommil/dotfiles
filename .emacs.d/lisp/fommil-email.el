;;; fommil-email.el --- Email Support -*- lexical-binding: t -*-

;; Copyright (C) 2018 Sam Halliday
;; License: http://www.gnu.org/licenses/lgpl-3.0.en.html

;;; Commentary:
;;
;;  Email
;;
;;; Code:
(require 'use-package)

(use-package notmuch
  :commands notmuch
  :init
  (setq
   mail-user-agent 'message-user-agent
   user-mail-address "sam.halliday@gmail.com"
   send-mail-function 'sendmail-send-it
   message-kill-buffer-on-exit t
   message-citation-line-format "\n%N wrote:"
   message-citation-line-function #'message-insert-formatted-citation-line
   message-signature "Best regards,\nSam\n<#part sign=pgpmime>"
   mml-secure-openpgp-sign-with-sender t
   epa-file-name-regexp (rx "." (| "gpg" "asc") eos)
   mm-text-html-renderer 'lynx
   notmuch-show-logo nil
   notmuch-search-line-faces '(("unread" :weight bold)
                               ("flagged" :inherit 'font-lock-string-face))
   notmuch-fcc-dirs nil
   notmuch-search-oldest-first nil
   notmuch-saved-searches '((:name "inbox" :key "i" :query "tag:inbox")
                            (:name "unread" :key "u" :query "tag:unread")
                            (:name "flagged" :key "f" :query "tag:flagged")
                            (:name "drafts" :key "d" :query "tag:draft")
                            (:name "all" :key "a" :query "*")))
  :config
  (add-hook 'message-setup-hook #'company-mode)
  ;; we don't use the mml-secure-sign-* functions because they put the part
  ;; before the signature. Instead, we hack the signature to have it at the end.
  ;; It's very unfortunate that there is no way to customise this.
  ;;
  ;; (add-hook 'message-setup-hook #'mml-secure-sign-pgpmime)
  )

(provide 'fommil-email)

;;; fommil-email.el ends here
