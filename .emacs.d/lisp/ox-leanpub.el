;;; ox-leanpub.el --- Leanpub Markdown Back-End for Org Export Engine

;; Author: Juan Reyero <juan _at! juanreyero.com>
;; Author: Sam Halliday
;; Keywords: org, wp, markdown, leanpub

;;; Commentary:

;;; Small adaptation of ox-md.el to make the exported markdown work
;;; better for Leanpub (http://leanpub.com) publication.

;;; Code:

(eval-when-compile (require 'cl))
(require 'ox-md)
(require 'ox-gfm)
(require 's)

;; FIXME: inherit from gfm or copy the functions we need check that we
;;        don't copy pasta anything from ox-md
(org-export-define-derived-backend 'leanpub 'md
  :menu-entry
  ;; FIXME: functions should call the leanpub-export
  ;;        (and remove these useless buffer / file exporters)
  '(?L "Export to Leanpub Markdown"
       ((?L "To temporary buffer"
	    (lambda (a s v b) (org-leanpub-export-as-markdown a s v)))
	(?l "To file" (lambda (a s v b) (org-leanpub-export-to-markdown a s v)))
	(?o "To file and open"
	    (lambda (a s v b)
	      (if a (org-leanpub-export-to-markdown t s v)
		(org-open-file (org-leanpub-export-to-markdown nil s v)))))))
  :translate-alist '((fixed-width . org-leanpub-fixed-width-block)
                     (example-block . org-leanpub-fixed-width-block)
                     (src-block . org-leanpub-src-block)
                     (special-block . org-leanpub-special-block)
                     (plain-text . org-leanpub-plain-text)
                     (inner-template . org-leanpub-inner-template)
                     (footnote-reference . org-leanpub-footnote-reference)
                     (headline . org-leanpub-headline)
                     (link . org-leanpub-link)
                     (latex-fragment . org-leanpub-latex-fragment)
                     (table-cell . org-gfm-table-cell)
                     (table-row . org-gfm-table-row)
                     ;; NOTE attr_leanpub is not supported
                     ;; https://leanpub.com/help/manual#leanpub-auto-tables
                     (table . org-gfm-table)))

(defun org-leanpub-latex-fragment (latex-fragment contents info)
  "Transcode a LATEX-FRAGMENT object from Org to Markdown.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (format "{$$}%s{/$$}"
          ;; Removes the \[, \] and $ that mark latex fragments
          (replace-regexp-in-string
           "\\\\\\[\\|\\\\\\]\\|\\$" ""
           (org-element-property :value latex-fragment))))

;;; Adding the id so that crosslinks work.
(defun org-leanpub-headline (headline contents info)
  (concat (let ((id (org-element-property :ID headline)))
            (if id
                (format "{#L%s}\n" id)
              ""))
          (org-md-headline headline contents info)))

(defun org-leanpub-inner-template (contents info)
  "Return complete document string after markdown conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options.  Required in order to add footnote
definitions at the end."
  (concat
   contents
   "\n\n"
   (let ((definitions (org-export-collect-footnote-definitions
                       info (plist-get info :parse-tree))))
     ;; Looks like leanpub do not like : in labels.
     (mapconcat (lambda (ref)
                  (let ((id (format "[^%s]: " (replace-regexp-in-string
                                               ":" "_"
                                               (let ((label (cadr ref)))
                                                (if label
                                                    label
                                                  (car ref)))))))
                    (let ((def (nth 2 ref)))
                      (concat id (org-export-data def info)))))
                definitions "\n\n"))))

(defun org-leanpub-footnote-reference (footnote contents info)
  ;; Looks like leanpub do not like : in labels.
  (format "[^%s]"
          (replace-regexp-in-string
           ":" "_"
           (let ((label (org-element-property :label footnote)))
             (if label
                 label
               (org-export-get-footnote-number footnote info))))))

(defun org-leanpub-plain-text (text info)
  text)

;;; {lang="python"}
;;; ~~~~~~~~
;;; def longitude_circle(diameter):
;;;     return math.pi * diameter
;;; longitude(10)
;;; ~~~~~~~~
(defun org-leanpub-src-block (src-block contents info)
  "Transcode SRC-BLOCK element into Markdown format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (let ((lang (org-element-property :language src-block)))
    (format
     ;;"{lang=\"%s\"}\n~~~~~~~~\n%s~~~~~~~~"
     ;; colour theme for code is truly awful, looks like a clown!
     ;; https://groups.google.com/forum/#!topic/leanpub/HmDGC6CgA8w
     "{lang=\"text\"}\n~~~~~~~~\n%s\n~~~~~~~~"
     (replace-regexp-in-string
      "^" "  "
      (s-trim
       (org-remove-indentation
        (org-element-property :value src-block)))))))

;;; A> wibble
;;; A> wibble
;;; A> I'm a fish
(defun org-leanpub-special-block (special-block contents info)
  (pcase
      (org-element-property :type special-block)
    ("ASIDE" (replace-regexp-in-string
              "^" "A> "
              (s-trim (org-remove-indentation contents))))
    ("TIP" (replace-regexp-in-string
            "^" "T> "
            (s-trim (org-remove-indentation contents))))
    ("WARNING" (replace-regexp-in-string
                "^" "W> "
                (s-trim (org-remove-indentation contents))))
    ("ERROR" (replace-regexp-in-string
              "^" "E> "
              (s-trim (org-remove-indentation contents))))
    ("INFO" (replace-regexp-in-string
             "^" "I> "
             (s-trim (org-remove-indentation contents))))
    ("QUESTION" (replace-regexp-in-string
                 "^" "Q> "
                 (s-trim (org-remove-indentation contents))))
    ("DISCUSS" (replace-regexp-in-string
                "^" "D> "
                (s-trim (org-remove-indentation contents))))
    ("EXERCISE" (replace-regexp-in-string
                 "^" "X> "
                 (s-trim (org-remove-indentation contents))))
    (_ (org-html-special-block special-block contents info))))

;;; A> {linenos=off}
;;; A> ~~~~~~~~
;;; A> 123.0
;;; A> ~~~~~~~~
(defun org-leanpub-fixed-width-block (src-block contents info)
  "Transcode FIXED-WIDTH-BLOCK element into Markdown format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (replace-regexp-in-string
   "^" "A> "
   (format "{linenos=off}\n~~~~~~~~\n%s~~~~~~~~"
           (org-remove-indentation
            (org-element-property :value src-block)))))

(defun org-leanpub-link (link contents info)
  "Transcode a link object into Markdown format.
CONTENTS is the link's description.  INFO is a plist used as
a communication channel."
  (let ((type (org-element-property :type link)))
    (cond ((member type '("custom-id" "id"))
           (let ((id (org-element-property :path link)))
             (format "[%s](#L%s)" contents id)))
          ((org-export-inline-image-p link org-html-inline-image-rules)
           (let ((path (let ((raw-path (org-element-property :path link)))
                         (if (not (file-name-absolute-p raw-path)) raw-path
                           (expand-file-name raw-path)))))
             ;; HACK: using caption for width
;;             (message "%s" (org-element-property
;;                            :width
;;                            (org-export-get-parent-element link)))
             (format "{width=%s%%}\n![](%s)"
                     (let ((caption (org-export-get-caption
                                     (org-export-get-parent-element link))))
                       (if caption
                           (org-export-data caption info)
                         "60"))
                     path)))
          (t (let* ((raw-path (org-element-property :path link))
                    (path (if (member type '("http" "https" "ftp"))
                              (concat type ":" raw-path)
                            nil)))
               (if path
                   (if (not contents) (format "<%s>" path)
                     (format "[%s](%s)" contents path))
                 contents))))))

;;; Interactive function

;;;###autoload
(defun org-leanpub-export-as-markdown (&optional async subtreep visible-only)
  "Export current buffer to a Markdown buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Export is done in a buffer named \"*Org MD Export*\", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (org-export-to-buffer 'leanpub "*Org LEANPUB Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-leanpub-export-to-markdown (&optional async subtreep visible-only)
  "Export current buffer to a Leanpub's compatible Markdown file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".md" subtreep)))
    (org-export-to-file 'leanpub outfile async subtreep visible-only)))

;;;###autoload
(defun org-leanpub-publish-to-leanpub (plist filename pub-dir)
  "Publish an org file to leanpub.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'leanpub filename ".md" plist pub-dir))

(provide 'ox-leanpub)

;;; ox-leanpub.el ends here
