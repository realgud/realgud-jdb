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

;;  `realgud:node-debug' Main interface to older "node debugb" debugger via Emacs

(require 'cl-lib)
(require 'load-relative)
(require 'realgud)
(require-relative-list '("core" "track-mode") "realgud:node-debug-")

;; This is needed, or at least the docstring part of it is needed to
;; get the customization menu to work in Emacs 24.
(defgroup realgud:node-debug nil
  "The realgud interface to the node-debug debugger"
  :group 'realgud
  :version "24.3")

;; -------------------------------------------------------------------
;; User-definable variables
;;

(defcustom realgud:node-debug-command-name
  "node debug"
  "File name for executing the Javascript debugger and command options.
This should be an executable on your path, or an absolute file name."
  :type 'string
  :group 'realgud:node-debug)

;; -------------------------------------------------------------------
;; The end.
;;

(declare-function node-debug-track-mode     'realgud-node-debug-track-mode)
(declare-function node-debug-query-cmdline  'realgud:node-debug-core)
(declare-function node-debug-parse-cmd-args 'realgud:node-debug-core)

;;;###autoload
(defun realgud:node-debug (&optional opt-cmd-line no-reset)
  "Invoke the node-debug shell debugger and start the Emacs user interface.

String OPT-CMD-LINE specifies how to run node-debug.

OPT-CMD-LINE is treated like a shell string; arguments are
tokenized by `split-string-and-unquote'.  The tokenized string is
parsed by `node-debug-parse-cmd-args' and path elements found by that
are expanded using `realgud:expand-file-name-if-exists'.

Normally, command buffers are reused when the same debugger is
reinvoked inside a command buffer with a similar command.  If we
discover that the buffer has prior command-buffer information and
NO-RESET is nil, then that information which may point into other
buffers and source buffers which may contain marks and fringe or
marginal icons is reset.  See `loc-changes-clear-buffer' to clear
fringe and marginal icons."
  (interactive)
  (let ((cmd-buf
	 (realgud:run-debugger "node-debug"
			       'node-debug-query-cmdline 'node-debug-parse-cmd-args
			       'realgud:node-debug-minibuffer-history
			       opt-cmd-line no-reset)))
    ;; (if cmd-buf
    ;; 	(with-current-buffer cmd-buf
    ;; 	  ;; FIXME should allow customization whether to do or not
    ;; 	  ;; and also only do if hook is not already there.
    ;; 	  (realgud:remove-ansi-schmutz)
    ;; 	  )
    ;;   )
    ))

(defalias 'node-debug 'realgud:node-debug)

(provide-me "realgud-")
