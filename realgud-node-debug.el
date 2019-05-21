;;; realgud-node-debug.el --- Realgud front-end to older nodejs "node debug" -*- lexical-binding: t -*-

;; Author: Rocky Bernstein <rocky@gnu.org>
;; Version: 1.0.0
;; Package-Type: multi
;; Package-Requires: ((realgud "1.4.5") (load-relative "1.2") (cl-lib "0.5") (emacs "24"))
;; URL: http://github.com/realgud/realgud-node-debug
;; Compatibility: GNU Emacs 24.x

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

;;; Commentary:

;; Provides realgud support for the older "node debug" used up into node
;; version 6 and deprecated starting with node version 8.
;; https://nodejs.org/dist/latest-v6.x/docs/api/
;;

;;; Code:

;; Press C-x C-e at the end of the next line configure the program in
;; for building via "make" to get set up.
;; (compile (format "EMACSLOADPATH=:%s:%s:%s:%s ./autogen.sh" (file-name-directory (locate-library "test-simple.elc")) (file-name-directory (locate-library "realgud.elc")) (file-name-directory (locate-library "load-relative.elc")) (file-name-directory (locate-library "loc-changes.elc"))))

(require 'load-relative)

(defgroup realgud-node-debug  nil
  "Realgud interface to the older 'node debug' debugger"
  :group 'realgud
  :version "24.3")

(require-relative-list '( "./realgud-node-debug/main" ) "realgud-")
(load-relative "./realgud-node-debug/main.el")

(provide-me)

;;; realgud-node-debug.el ends here
