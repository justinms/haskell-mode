;;; haskell-completions-tests.el --- Tests for Haskell Completion package

;; Copyright © 2015 Athur Fayzrakhmanov. All rights reserved.

;; This file is part of haskell-mode package.
;; You can contact with authors using GitHub issue tracker:
;; https://github.com/haskell/haskell-mode/issues

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides regression tests for haskell-completions package.

;;; Code:

(require 'ert)
(require 'haskell-mode)
(require 'haskell-completions)


(ert-deftest haskell-completions-can-grab-prefix-test ()
  "Tests the function `haskell-completions-can-grab-prefix'."
  (with-temp-buffer
    (haskell-mode)
    (should (eql nil (haskell-completions-can-grab-prefix)))
    (insert " ")
    (should (eql nil (haskell-completions-can-grab-prefix)))
    (insert "a")
    (should (eql t (haskell-completions-can-grab-prefix)))
    (save-excursion
      (insert " ")
      (should (eql nil (haskell-completions-can-grab-prefix)))
      (insert "bc-")
      (should (eql t (haskell-completions-can-grab-prefix)))
      (insert "\n")
      (should (eql nil (haskell-completions-can-grab-prefix)))
      (insert "def:#!")
      (should (eql t (haskell-completions-can-grab-prefix))))
    (should (eql t (haskell-completions-can-grab-prefix)))
    ;; punctuation tests
    (save-excursion (insert ")"))
    (should (eql t (haskell-completions-can-grab-prefix)))
    (save-excursion (insert ","))
    (should (eql t (haskell-completions-can-grab-prefix)))
    (save-excursion (insert "'"))
    (should (eql t (haskell-completions-can-grab-prefix)))
    ;; should return nil in the middle of word
    (save-excursion (insert "bcd"))
    (should (eql nil (haskell-completions-can-grab-prefix)))
    ;; region case
    (let ((p (point)))
      (goto-char (point-min))
      (push-mark)
      (goto-char p)
      (activate-mark)
      (should (eql nil (haskell-completions-can-grab-prefix))))))


(ert-deftest haskell-completions-grab-pragma-prefix-nil-cases-test ()
  "Tests the function `haskell-completions-grab-pragma-prefix'
within empty pragma comment {-# #-} and outside of it."
  (with-temp-buffer
    (haskell-mode)
    (goto-char (point-min))
    (insert "{")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "-")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "#")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "  ")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "#")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "-")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "}")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "\n")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert "main")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))
    (insert ":: IO ()")
    (should (eql nil (haskell-completions-grab-pragma-prefix)))))

(ert-deftest haskell-completions-grab-pragma-name-prefix-test ()
  "Tests the function `haskell-completions-grab-pragma-prefix'
for pragma names completions such as WARNING, LANGUAGE,
DEPRECATED and etc."
  (let ((expected (list 5 8 "LAN" 'haskell-completions-pragma-name-prefix)))
    (with-temp-buffer
      (haskell-mode)
      (goto-char (point-min))
      (insert "{-# LAN")
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (save-excursion (insert " #-}"))
      ;; should work in case of closed comment, e.g. {-# LAN| #-}
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      ;; pragma function should work in the middle of word
      (backward-char)
      (should (not (equal expected (haskell-completions-grab-pragma-prefix)))))
    (with-temp-buffer
      (haskell-mode)
      (goto-char (point-min))
      (insert "{-#\nLAN")
      ;; should work for multiline case
      (should (equal expected (haskell-completions-grab-pragma-prefix))))))

(ert-deftest haskell-completions-grab-ghc-options-prefix-test-01 ()
  "Tests the function `haskell-completions-grab-pragma-prefix'
for GHC options prefixes."
  (let (expected)
    (with-temp-buffer
      (haskell-mode)
      (goto-char (point-min))
      (setq expected
            (list 5 16 "OPTIONS_GHC" 'haskell-completions-pragma-name-prefix))
      (insert "{-# OPTIONS_GHC")
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert " --opt1")
      (setq expected
            (list 17 23 "--opt1" 'haskell-completions-ghc-option-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert "    -XOpt-2")
      (setq expected
            (list 27 34 "-XOpt-2" 'haskell-completions-ghc-option-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (save-excursion
        (insert "\n")
        (insert "\"new-line\"")
        ;; should handle multiline case
        (setq
         expected
         (list 35 45 "\"new-line\"" 'haskell-completions-ghc-option-prefix))
        (should (equal expected (haskell-completions-grab-pragma-prefix)))
        (insert " test    ")
        (should (eql nil (haskell-completions-grab-pragma-prefix)))
        (insert "#-}"))
      ;; should work in case of closed comment, e.g. {-# OPTIONS_GHC xyz| #-}
      (setq expected
            (list 27 34 "-XOpt-2" 'haskell-completions-ghc-option-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (backward-char)
      ;; pragma function should work in the middle of word
      (should (not (eql nil (haskell-completions-grab-pragma-prefix)))))))

(ert-deftest haskell-completions-grab-ghc-options-prefix-test-02 ()
  "Tests the function `haskell-completions-grab-pragma-prefix'
for GHC options prefixes.  Same tests as above for obsolete
OPTIONS pragma."
  (let (expected)
    (with-temp-buffer
      (haskell-mode)
      (goto-char (point-min))
      (insert "{-# OPTIONS")
      (setq expected
            (list 5 12 "OPTIONS" 'haskell-completions-pragma-name-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert " --opt1")
      (setq expected
            (list 13 19 "--opt1" 'haskell-completions-ghc-option-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert "    -XOpt-2")
      (setq expected
            (list 23 30 "-XOpt-2" 'haskell-completions-ghc-option-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (save-excursion
        (insert "\n")
        (insert "\"new-line\"")
        ;; should handle multiline case
        (setq
         expected
         (list 31 41 "\"new-line\"" 'haskell-completions-ghc-option-prefix))
        (should (equal expected (haskell-completions-grab-pragma-prefix)))
        (insert " test    ")
        (should (eql nil (haskell-completions-grab-pragma-prefix)))
        (insert "#-}"))
      ;; should work in case of closed comment
      (setq expected
            (list 23 30 "-XOpt-2" 'haskell-completions-ghc-option-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (backward-char)
      ;; pragma function should work in the middle of word
      (should (not (eql nil (haskell-completions-grab-pragma-prefix)))))))

(ert-deftest haskell-completions-grab-language-extenstion-prefix-test ()
  "Tests both function `haskell-completions-grab-pragma-prefix'
and function `haskell-completions-grab-prefix' for language
extension prefixes."
  (let (expected)
    (with-temp-buffer
      (haskell-mode)
      (goto-char (point-min))
      (insert "{-# LANGUAGE")
      (setq expected
            (list 5 13 "LANGUAGE" 'haskell-completions-pragma-name-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert " Rec")
      (setq expected
            (list 14 17 "Rec" 'haskell-completions-language-extension-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert ",    -XOpt-2")
      (setq
       expected
       (list 22 29 "-XOpt-2" 'haskell-completions-language-extension-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert ",\n")
      (insert "\"new-line\"")
      ;; should handle multiline case
      (setq expected
            (list 31
                  41
                  "\"new-line\""
                  'haskell-completions-language-extension-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (insert " -test")
      (save-excursion (insert "     #-}"))
      ;; should work in case of closed comment
      (setq expected
            (list 42 47 "-test" 'haskell-completions-language-extension-prefix))
      (should (equal expected (haskell-completions-grab-pragma-prefix)))
      (backward-char)
      ;; pragma function should work in the middle of the word
      (should (not (eql nil (haskell-completions-grab-pragma-prefix)))))))


(provide 'haskell-completions-tests)
;;; haskell-completions-tests.el ends here
