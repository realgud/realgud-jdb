;; Copyright (C) 2019 Free Software Foundation, Inc
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(eval-when-compile (require 'cl-lib))

(require 'realgud)

(declare-function realgud:expand-file-name-if-exists 'realgud-core)
(declare-function realgud-lang-mode? 'realgud-lang)
(declare-function realgud-parse-command-arg 'realgud-core)
(declare-function realgud-query-cmdline 'realgud-core)

;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(declare-function realgud:expand-file-name-if-exists 'realgud-core)
(declare-function realgud-parse-command-arg  'realgud-core)
(declare-function realgud-query-cmdline      'realgud-core)
(declare-function realgud-suggest-invocation 'realgud-core)

;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(defvar realgud:node-debug-minibuffer-history nil
  "Minibuffer history list for the command `node-debug'.")

(easy-mmode-defmap realgud:node-debug-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of node-debug startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable chould be generalized, perhaps via a macro.
(defun node-debug-query-cmdline (&optional opt-debugger)
  (realgud-query-cmdline
   'realgud:node-debug-suggest-invocation
   realgud:node-debug-minibuffer-local-map
   'realgud:node-debug-minibuffer-history
   opt-debugger))

;;; FIXME: DRY this with other *-parse-cmd-args routines
(defun node-debug-parse-cmd-args (orig-args)
  "Parse command line ORIG-ARGS for the name of script to debug.

ORIG-ARGS should contain a tokenized list of the command line to run.

We return the a list containing
* the name of the debugger given (e.g. ‘node-debug’) and its arguments ,
  a list of strings
* the script name and its arguments - list of strings

For example for the following input:
  (map 'list 'symbol-name
   '(node --interactive --debugger-port 5858 /tmp node-debug ./gcd.js a b))

we might return:
   ((\"node\" \"--interactive\" \"--debugger-port\" \"5858\") nil
    (\"/tmp/gcd.js\" \"a\" \"b\"))

Note that path elements have been expanded via `expand-file-name'."

  ;; Parse the following kind of pattern:
  ;;  node node-debug-options script-name script-options
  (let (
	(args orig-args)
	(pair)          ;; temp return from
	(node-two-args '("-debugger_port" "C" "D" "i" "l" "m" "-module" "x"))
	;; node doesn't have any optional two-arg options
	(node-opt-two-args '())

	;; One dash is added automatically to the below, so
	;; h is really -h and -debugger_port is really --debugger_port.
	(node-debug-two-args '("-debugger_port"))
	(node-debug-opt-two-args '())

	;; Things returned
	(script-name nil)
	(debugger-name nil)
	(interpreter-args '())
	(script-args '())
	)
    (if (not (and args))
	;; Got nothing: return '(nil, nil, nil)
	(list interpreter-args nil script-args)
      ;; else
      (progn
	;; Remove "node-debug" (or "nodemon" or "node") from invocation like:
	;; node-debug --node-debug-options script --script-options
	(setq debugger-name (file-name-sans-extension
			     (file-name-nondirectory (car args))))
	(unless (string-match "^node\\(?:js\\|mon\\)?$" debugger-name)
	  (message
	   "Expecting debugger name `%s' to be `node', `nodemon', or `node-debug'"
	   debugger-name))
	(setq interpreter-args (list (pop args)))

	;; Skip to the first non-option argument.
	(while (and args (not script-name))
	  (let ((arg (car args)))
	    (cond
	     ((equal "debug" arg)
	      (nconc interpreter-args (list arg))
	      (setq args (cdr args))
	      )

	     ;; Options with arguments.
	     ((string-match "^-" arg)
	      (setq pair (realgud-parse-command-arg
			  args node-debug-two-args node-debug-opt-two-args))
	      (nconc interpreter-args (car pair))
	      (setq args (cadr pair)))
	     ;; Anything else must be the script to debug.
	     (t (setq script-name (realgud:expand-file-name-if-exists arg))
	       (setq script-args (cons script-name (cdr args))))
	     )))
	(list interpreter-args nil script-args)))
    ))

;; To silence Warning: reference to free variable
(defvar realgud:node-debug-command-name)

(defun realgud:node-debug-suggest-invocation (debugger-name)
  "Suggest a ‘node-debug’ command invocation via `realgud-suggest-invocaton'.
Argument DEBUGGER-NAME is not used - it is there function compatibility."
  (realgud-suggest-invocation realgud:node-debug-command-name
			      realgud:node-debug-minibuffer-history
			      "js" "\\.js$"))

(defun realgud:node-debug-remove-ansi-shmutz()
  "Remove ASCII escape sequences that node.js 'decorates' in
prompts and interactive output."
  (add-to-list
   'comint-preoutput-filter-functions
   (lambda (output)
     (replace-regexp-in-string "\033\\[[0-9]+[GKJ]" "" output)))
  )

(defun realgud:node-debug-reset ()
  "Node-Debug cleanup - remove debugger's internal buffers (frame, breakpoints, etc.)."
  (interactive)
  ;; (node-debug-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*node-debug-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun node-debug-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'node-debug-debugger-support-minor-mode minor-mode-map-alist)
;; 	  node-debug-debugger-support-minor-mode-map-when-deactive))


(defun realgud:node-debug-customize ()
  "Use `customize' to edit the settings of the `node-debug' debugger."
  (interactive)
  (customize-group 'realgud:node-debug))

(provide-me "realgud:node-debug-")
