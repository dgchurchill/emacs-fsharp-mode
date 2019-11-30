;;; integration-tests.el ---                         -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Jürgen Hötzel

;; Author: Jürgen Hötzel <juergen@hoetzel.info>
;; Keywords: abbrev, abbrev

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This file is part of fsharp-mode

;;; Code:

(require 'buttercup)
(require 'eglot-fsharp)
(require 'eglot-tests)

(describe "F# LSP server"
  (it "Can be installed"
    (eglot-fsharp--maybe-install)
    (expect (file-exists-p  (eglot-fsharp--path-to-server)) :to-be t))
  (it "is enabled on F# Files"
    (with-current-buffer (eglot--find-file-noselect "test/Test1/FileTwo.fs")
      (eglot--tests-connect 30)
      (expect (type-of (eglot--current-server-or-lose)) :to-be 'eglot-fsautocomplete)))
  (it "provides completion"
    (with-current-buffer (eglot--find-file-noselect "test/Test1/FileTwo.fs")
      (expect (plist-get (eglot--capabilities (eglot--current-server-or-lose)) :completionProvider) :not :to-be nil)))
  (it "completes function in other modules"
    (with-current-buffer (eglot--find-file-noselect "test/Test1/Program.fs")
      (search-forward "X.func")
      (delete-char -3)
      ;; ERROR in fsautocomplet.exe?  Should block instead of "no type check results"
      (eglot--sniffing (:server-notifications s-notifs)
        (eglot--wait-for (s-notifs 90)
            (&key _id method &allow-other-keys)
          (string= method "textDocument/publishDiagnostics")))
      (completion-at-point)
      (expect (looking-back "X\\.func") :to-be t)))
  (it "doesn't throw error when definition does not exist"
      (with-current-buffer (eglot--find-file-noselect "test/Test1/Program.fs")
	(goto-char 253)
	(expect (current-word) :to-equal "printfn") ;sanity check
	(expect
	 (condition-case err
	     (call-interactively #'xref-find-definitions)
	   (user-error
	    (cadr err)))
	 :to-equal "No definitions found for: LSP identifier at point."))))

(provide 'integration-tests)
;;; integration-tests.el ends here
