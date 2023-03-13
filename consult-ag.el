;;; consult-ag.el --- The silver searcher integration using Consult -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Kanon Kakuno

;; Author: Kanon Kakuno <yadex205@outlook.jp> and contributors
;; Homepage: https://github.com/yadex205/consult-ag
;; Package-Requires: ((emacs "27.1") (consult "0.32"))
;; SPDX-License-Identifier: MIT
;; Version: 0.2.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; consult-ag provides interfaces for using `ag` (The Silver Searcher).
;; To use this, turn on `consult-ag` in your init-file or interactively.

;;; Code:

(eval-when-compile ; IDK but required for byte-compile
  (require 'cl-lib)
  (require 'subr-x))
(require 'consult)

(defconst consult-ag--match-regexp
  "\\`\\(?:\\./\\)?\\([^:]+\\):\\([0-9]+\\):\\([0-9]+:\\)")

(defun consult-ag--grep-format (async builder)
  "Return ASYNC function highlighting grep match results.
BUILDER is the command line builder function."
  (let (highlight)
    (lambda (action)
      (cond
       ((stringp action)
        (setq highlight (cdr (funcall builder action)))
        (funcall async action))
       ((consp action)
        (let ((file "") (file-len 0) result)
          (save-match-data
            (dolist (str action)
              (when (and (string-match consult-ag--match-regexp str)
                         ;; Filter out empty context lines
                         (or (/= (aref str (match-beginning 3)) ?-)
                             (/= (match-end 0) (length str))))
                ;; We share the file name across candidates to reduce
                ;; the amount of allocated memory.
                (unless (and (= file-len (- (match-end 1) (match-beginning 1)))
                             (eq t (compare-strings
                                    file 0 file-len
                                    str (match-beginning 1) (match-end 1) nil)))
                  (setq file (match-string 1 str)
                        file-len (length file)))
                (let* ((line (match-string 2 str))
                       (ctx (= (aref str (match-beginning 3)) ?-))
                       (sep (if ctx "-" ":"))
                       (content (substring str (match-end 0)))
                       (line-len (length line)))
                  (when (length> content consult-grep-max-columns)
                    (setq content (substring content 0 consult-grep-max-columns)))
                  (when highlight
                    (funcall highlight content))
                  (setq str (concat file sep line sep content))
                  ;; Store file name in order to avoid allocations in `consult--prefix-group'
                  (add-text-properties 0 file-len `(face consult-file consult--prefix-group ,file) str)
                  (put-text-property (1+ file-len) (+ 1 file-len line-len) 'face 'consult-line-number str)
                  (when ctx
                    (add-face-text-property (+ 2 file-len line-len) (length str) 'consult-grep-context 'append str))
                  (push str result)))))
          (funcall async (nreverse result))))
       (t (funcall async action))))))

(defun consult-ag--make-builder (paths)
  (let ((cmd (consult--build-args "ag --vimgrep --search-zip")))
    (lambda (input)
      (pcase-let* ((`(,arg . ,opts) (consult--command-split input))
		   (flags (append cmd opts))
		   (ignore-case (or (member "-i" flags) (member "--ignore-case" flags))))
	(if (or (member "-F" flags) (member "--fixed-strings" flags))
	    (cons (append cmd (list arg) opts paths)
		  (apply-partially #'consult--highlight-regexps
				   (list (regexp-quote arg)) ignore-case))
	  (pcase-let ((`(,re . ,hl) (funcall consult--regexp-compiler arg 'pcre ignore-case)))
	    (when re
	      (cons (append cmd
			    opts
			    (list (consult--join-regexps re 'pcre))
			    paths)
		    hl))))))))


;;;###autoload
(defun consult-ag (&optional dir initial)
  (interactive "P")
  (pcase-let* ((`(,prompt ,paths ,dir) (consult--directory-prompt "Ag" dir))
	       (default-directory dir)
	       (builder (consult-ag--make-builder paths)))
    (consult--read
     (consult--async-command builder
       (consult-ag--grep-format builder)
       :file-handler t)
     :prompt prompt
     :lookup #'consult--lookup-member
     :state (consult--grep-state)
     :initial (consult--async-split-initial initial)
     :add-history (consult--async-split-thingatpt 'symbol)
     :require-match t
     :category 'consult-grep
     :group #'consult--prefix-group
     :history '(:input consult--grep-history)
     :sort nil)))

(provide 'consult-ag)

;;; consult-ag.el ends here
