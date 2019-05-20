;; Copyright (C) 2019 Free Software Foundation, Inc
;; Author: Rocky Bernstein

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

;;; "node debug" debugger

;;; Note: this protocol is was in use up until node version 6 and
;;; became became deprecated with node version 8.  The newer protocol
;;; is in realgud-node-inspect
;;;
;;; Regular expressions for nodejs Javascript debugger with "node debug" protocol.

(eval-when-compile (require 'cl-lib))   ;For setf.

(require 'realgud)
(require 'realgud-lang-js)
(require 'ansi-color)

(defvar realgud:node-debug-pat-hash)
(declare-function make-realgud-loc-pat (realgud-loc))

(defvar realgud:node-debug-pat-hash (make-hash-table :test 'equal)
  "Hash key is the what kind of pattern we want to match:
backtrace, prompt, etc.  The values of a hash entry is a
realgud-loc-pat struct")

;; before a command prompt.
;; For example:
;;   break in /home/indutny/Code/git/indutny/myscript.js:1
(setf (gethash "loc" realgud:node-debug-pat-hash)
      (make-realgud-loc-pat
       :regexp (format
		"\\(?:%s\\)*\\(?:break\\|exception\\) in %s:%s"
		realgud:js-term-escape "\\([^:]+\\)"
		realgud:regexp-captured-num)
       :file-group 1
       :line-group 2))

;; Regular expression that describes a node-debug command prompt
;; For example:
;;   debug>
(setf (gethash "prompt" realgud:node-debug-pat-hash)
      (make-realgud-loc-pat
       :regexp (format "^\\(?:%s\\)*debug> " realgud:js-term-escape)
       ))

;; Need an improved setbreak for this.
;; ;;  Regular expression that describes a "breakpoint set" line
;; ;;   3 const armlet = require('armlet');
;; ;; * 4 const client = new armlet.Client(
;; ;; ^^^^
;; ;;
;; (setf (gethash "brkpt-set" realgud:node-debug-pat-hash)
;;       (make-realgud-loc-pat
;;        :regexp "^\*[ ]*\\([0-9]+\\) \\(.+\\)"
;;        :line-group 1
;;        :text-group 2))

;; Regular expression that describes a V8 backtrace line.
;; For example:
;;    at repl:1:7
;;    at Interface.controlEval (/src/external-vcs/github/trepanjs/lib/interface.js:352:18)
;;    at REPLServer.b [as eval] (domain.js:183:18)
(setf (gethash "lang-backtrace" realgud:node-debug-pat-hash)
  realgud:js-backtrace-loc-pat)

;; Regular expression that describes a debugger "delete" (breakpoint)
;; response.
;; For example:
;;   Removed 1 breakpoint(s).
(setf (gethash "brkpt-del" realgud:node-debug-pat-hash)
      (make-realgud-loc-pat
       :regexp (format "^Removed %s breakpoint(s).\n"
		       realgud:regexp-captured-num)
       :num 1))


(defconst realgud:node-debug-frame-start-regexp  "\\(?:^\\|\n\\)\\(?:#\\)")
(defconst realgud:node-debug-frame-num-regexp    realgud:regexp-captured-num)
(defconst realgud:node-debug-frame-module-regexp "[^ \t\n]+")
(defconst realgud:node-debug-frame-file-regexp   "[^ \t\n]+")

;; Regular expression that describes a node-debug location generally shown
;; Regular expression that describes a debugger "backtrace" command line.
;; For example:
;; #0 module.js:380:17
;; #1 dbgtest.js:3:9
;; #2 Module._compile module.js:456:26
;; #3 Module._extensions..js module.js:474:10
;; #4 Module.load module.js:356:32
;; #5 Module._load module.js:312:12
;; #6 Module.runMain module.js:497:10
; ;#7 timers.js:110:15
(setf (gethash "debugger-backtrace" realgud:node-debug-pat-hash)
      (make-realgud-loc-pat
       :regexp 	(concat realgud:node-debug-frame-start-regexp
			realgud:node-debug-frame-num-regexp " "
			"\\(?:" realgud:node-debug-frame-module-regexp " \\)?"
			"\\(" realgud:node-debug-frame-file-regexp "\\)"
			":"
			realgud:regexp-captured-num
			":"
			realgud:regexp-captured-num
			)
       :num 1
       :file-group 2
       :line-group 3
       :char-offset-group 4))

(defconst realgud:node-debug-debugger-name "node-debug" "Name of debugger.")

;; ;; Regular expression that for a termination message.
;; (setf (gethash "termination" realgud:node-debug-pat-hash)
;;        "^node-debug: That's all, folks...\n")

(setf (gethash "font-lock-keywords" realgud:node-debug-pat-hash)
  '(
    ;; #0 module.js:380:17
    ;;  ^ ^^^^^^^^^ ^^^ ^^
    (concat realgud:node-debug-frame-start-regexp
	    realgud:node-debug-frame-num-regexp " "
	    "\\(?:" realgud:node-debug-frame-module-regexp " \\)?"
	    "\\(" realgud:node-debug-frame-file-regexp "\\)"
	    ":"
	    realgud:regexp-captured-num
	    )
     (1 realgud-file-name-face)
     (2 realgud-line-number-face)
     )
    )

(setf (gethash "node-debug" realgud-pat-hash)
      realgud:node-debug-pat-hash)

;;  Prefix used in variable names (e.g. short-key-mode-map) for
;; this debugger

(setf (gethash "node-debug" realgud:variable-basename-hash)
      "realgud:node-debug")

(defvar realgud:node-debug-command-hash (make-hash-table :test 'equal)
  "Hash key is command name like 'finish' and the value is the node-debug command to use, like 'out'.")

(setf (gethash realgud:node-debug-debugger-name
	       realgud-command-hash)
      realgud:node-debug-command-hash)

(setf (gethash "backtrace"  realgud:node-debug-command-hash) "backtrace")
(setf (gethash "break"      realgud:node-debug-command-hash)
      "setBreakpoint('%X',%l)")
(setf (gethash "clear"      realgud:node-debug-command-hash)
      "clearBreakpoint('%X', %l)")
(setf (gethash "continue"         realgud:node-debug-command-hash) "cont")
(setf (gethash "kill"             realgud:node-debug-command-hash) "kill")
(setf (gethash "quit"             realgud:node-debug-command-hash) ".exit")
(setf (gethash "finish"           realgud:node-debug-command-hash) "out")
(setf (gethash "shell"            realgud:node-debug-command-hash) "repl")
(setf (gethash "eval"             realgud:node-debug-command-hash) "exec('%s')")
(setf (gethash "info-breakpoints" realgud:node-debug-command-hash) "breakpoints")

;; We need aliases for step and next because the default would
;; do step 1 and node-debug doesn't handle this. And if it did,
;; it would probably look like step(1).
(setf (gethash "step"       realgud:node-debug-command-hash) "step")
(setf (gethash "next"       realgud:node-debug-command-hash) "next")

;; Unsupported features:
(setf (gethash "jump"       realgud:node-debug-command-hash) "*not-implemented*")
(setf (gethash "up"         realgud:node-debug-command-hash) "*not-implemented*")
(setf (gethash "down"       realgud:node-debug-command-hash) "*not-implemented*")
(setf (gethash "frame"      realgud:node-debug-command-hash) "*not-implemented*")

(setf (gethash "node-debug" realgud-command-hash) realgud:node-debug-command-hash)
(setf (gethash "node-debug" realgud-pat-hash) realgud:node-debug-pat-hash)

(provide-me "realgud:node-debug-")
