;;; erc-view-log.el --- Minor mode for viewing erc logs

;; Copyright (C) 2010 Antoine Levitt
;; Copyright (C) 2010 Thomas Riccardi

;; Author: Antoine Levitt
;;         Thomas Riccardi <riccardi.thomas@gmail.com>
;; Keywords: erc viewer logs colors

;; This program is free software. It comes without any warranty, to
;; the extent permitted by applicable law. You can redistribute it
;; and/or modify it under the terms of the Do What The Fuck You Want
;; To Public License, Version 2, as published by Sam Hocevar. See
;; http://sam.zoy.org/wtfpl/COPYING for more details.

;;; Description:
;; Set colors on an erc log file

;;; Installation:
;;    (require 'erc-view-log)
;;    (add-to-list 'auto-mode-alist '("\\.erclogs/.*\\.log" . erc-view-log-mode))

;;; Options:
;; - erc-view-log-nickname-face-function:
;;    A function that returns a face, given a nick, to colorize nicks.
;;    Can be nil to use standard erc face.
;; - erc-view-log-my-nickname-match:
;;    Either a regexp or a list of nicks, to match our own nickname.
;;    For the list, each nick should be unique and should not contain any regexps.

;;; TODO:
;; - r to reload the log
;; - handle priv messages?: erc-direct-msg-face
;; - handle nick for private messages?: erc-nick-msg-face
;; - use vlf.el for large logs? has to be adapted (no more major mode, and handle full lines...)

(require 'erc)


(defcustom erc-view-log-nickname-face-function
  nil
  "A function that returns a face, given a nick. nil to use default erc face."
  :type 'function)

(defcustom erc-view-log-my-nickname-match
  erc-nick
  "A match for my nickname: either a regexp, or a list of nicks."
  :type '(choice (regexp :tag "A regexp that matches my nick.")
		 (list :tag "A list of used nicks. Each nick should be unique and should not contain any regexps.")))


;; Warning: do not use group constructions ("\\(some regexp\\)") inside the following regexps
(defvar erc-view-log-timestamp-regexp
  ".*"
  "Regexp to match timestamps.")

(defvar erc-view-log-nickname-regexp
  erc-valid-nick-regexp
  "Regexp to match nicknames.")

(defvar erc-view-log-message-regexp
  ".*"
  "Regexp to match messages.")

(defvar erc-view-log-current-nick-regexp
  "\\*\\*\\* Users on .*: .*"
  "Regexp to match current nicks lines.")

(defvar erc-view-log-notice-regexp
  "\\*\\*\\* .*"
  "Regexp to match notices.")

(defvar erc-view-log-action-regexp
  (format "\\* %s .*" erc-valid-nick-regexp)
  "Regexp to match actions.")

(defvar erc-view-log-prompt-regexp
  erc-prompt
  "Regexp to match prompts.")


(defun erc-log-nick-get-face (nick)
  "Returns a face for the given nick."
  (if erc-view-log-nickname-face-function
      (apply erc-view-log-nickname-face-function (list nick))
    'erc-nick-default-face))

(defun erc-log-get-my-nick-regexp ()
  "Returns a regexp that matches my nick according to custom erc-view-log-my-nickname-match."
  (if (listp erc-view-log-my-nickname-match)
      (regexp-opt erc-view-log-my-nickname-match)
    erc-view-log-my-nickname-match))


;; warning: only works if erc-timestamp-format doesn't contains the pattern "<a_nickname>"
(defun erc-view-log-get-keywords ()
  "Returns the font-lock-defaults."
      (list
       ;; own message line
       `(,(format "^\\(%s\\) \\(<\\)\\(%s\\)\\(>\\)[ \t]\\(%s\\)$" erc-view-log-timestamp-regexp (erc-log-get-my-nick-regexp) erc-view-log-message-regexp)
	 (1 'erc-timestamp-face)
	 (2 'erc-default-face)
	 (3 'erc-my-nick-face)
	 (4 'erc-default-face)
	 (5 'erc-input-face) ;; my message
	 )
       ;; standard message line
       `(,(format "^\\(%s\\) \\(<\\)\\(%s\\)\\(>\\)[ \t]\\(%s\\)$" erc-view-log-timestamp-regexp erc-view-log-nickname-regexp erc-view-log-message-regexp)
	 (1 'erc-timestamp-face)
	 (2 'erc-default-face)
	 (3 (erc-log-nick-get-face (match-string 3)))
	 (4 'erc-default-face)
	 (5 'erc-default-face) ;; other message
	 )
       ;; current nicks line
       `(,(format "\\(%s\\) \\(%s\\)" erc-view-log-timestamp-regexp erc-view-log-current-nick-regexp)
	 (1 'erc-timestamp-face)
	 (2 'erc-current-nick-face)
	 )
       ;; notice line
       `(,(format "\\(%s\\) \\(%s\\)" erc-view-log-timestamp-regexp erc-view-log-notice-regexp)
	 (1 'erc-timestamp-face)
	 (2 'erc-notice-face)
	 )
       ;; action line
       `(,(format "\\(%s\\) \\(%s\\)" erc-view-log-timestamp-regexp erc-view-log-action-regexp)
	 (1 'erc-timestamp-face)
	 (2 'erc-action-face)
	 )
       ;; command line
       `(,(format "\\(%s\\) \\(%s\\) \\(/.*\\)" erc-view-log-timestamp-regexp erc-view-log-prompt-regexp)
	 (1 'erc-timestamp-face)
	 (2 'erc-prompt-face)
	 (3 'erc-command-indicator-face)
	 )
       ))


;; undefine some syntax that's messing up with our coloring (for instance, "")
(defvar erc-view-log-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\" ".   " st)
    (modify-syntax-entry ?\\ ".   " st)
    st)
  "Syntax table used while in `erc-view-log-mode'.")


(define-derived-mode erc-view-log-mode fundamental-mode
  "ERC View Log"
  (setq font-lock-defaults `(,(erc-view-log-get-keywords)))
  (setq buffer-read-only t))


(provide 'erc-view-log)

;;; erc-view-log.el ends here
