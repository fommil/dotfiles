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
   message-signature "Best regards,\nSam\n"
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
  (add-hook 'message-setup-hook #'mml-secure-sign-pgpmime))

(provide 'fommil-email)

;;; fommil-email.el ends here
