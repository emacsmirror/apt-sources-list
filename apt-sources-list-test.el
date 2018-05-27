;;; apt-sources-list-test.el --- Tests for apt-sources-list  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2017  Joe Wreschnig
;;
;; Author: Joe Wreschnig
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.


;;; Commentary:
;;
;; This file contains test cases for apt-sources-list.  Unless you’re
;; hacking on it you shouldn’t need to edit or run this file.


;;; Code:

(require 'apt-sources-list)
(require 'ert)

(defmacro with-temp-windowed-buffer (&rest body)
  "Like ‘with-temp-buffer’ but give the buffer a window during BODY.

This is necessary if you want to simulate sending keys."
  `(with-temp-buffer
     (set-window-buffer (selected-window) (current-buffer) t)
     ,@body))

(defmacro with-apt-sources-list (sources &rest body)
  "With buffer contents SOURCES, run BODY forms in ‘apt-sources-list-mode’."
  (declare (indent 1))
  `(with-temp-windowed-buffer
     (apt-sources-list-mode)
     (insert ,sources)
     (goto-char (point-min))
     ,@body))

(defmacro should-equal (expected actual)
  "Assert that EXPECTED is ‘equal’ to ACTUAL."
  `(should (equal ,expected ,actual)))

(defmacro should-eq (expected actual)
  "Assert that EXPECTED is ‘eq’ to ACTUAL."
  `(should (eq ,expected ,actual)))

(defmacro should-equal-buffer (contents)
  "Assert that the current buffer’s contents equals CONTENTS."
  `(should-equal (buffer-string) ,contents))

(defmacro should-use-face (face)
  "Assert that the current point’s face is FACE."
  `(should-eq (get-text-property (point) 'face) ,face))

(defmacro should-be-at-line (lineno)
  "Assert that the point is on line number LINENO."
  `(should-equal ,lineno (line-number-at-pos)))

(defun type (keys)
  "Simulate typing KEYS."
  (execute-kbd-macro (kbd keys)))

(ert-deftest apt-sources-list-test-invalid ()
  (with-apt-sources-list "invalid"
    (should-error (apt-sources-list-change-type)
                  :type 'apt-sources-list-not-found)
    (should-error (apt-sources-list-change-uri "http://foo")
                  :type 'apt-sources-list-not-found)))

(ert-deftest apt-sources-list-test-insert ()
  (with-apt-sources-list ""
    (type "C-c C-i RET deb.test RET RET RET")
    (should-equal-buffer "deb https://deb.test stable main"))

  (with-apt-sources-list ""
    (type "C-c C-i example RET deb.test RET RET RET")
    (should-equal-buffer "# example\ndeb https://deb.test stable main"))

  (with-apt-sources-list ""
    (type "C-c C-i RET deb.test RET M-0 C-k path/ RET")
    (should-equal-buffer "deb https://deb.test path/"))

  (with-apt-sources-list ""
    (type "C-u C-c C-i RET -src RET arch=amd64 RET deb.test RET RET")
    (should-equal-buffer
     "deb-src [arch=amd64] https://deb.test stable main")))

(ert-deftest apt-sources-list-test-replicate ()
  (with-apt-sources-list "deb http://deb.test/debian stable main"
    (type "C-c C-r")
    (should-equal-buffer
     "deb http://deb.test/debian stable main
deb-src http://deb.test/debian stable main")))

(ert-deftest apt-sources-list-test-change-type ()
  (with-apt-sources-list "deb http://deb.test/debian stable main"
    (type "C-c C-t")
    (should-equal-buffer "deb-src http://deb.test/debian stable main")
    (type "C-c C-t")
    (should-equal-buffer "deb http://deb.test/debian stable main")))

(ert-deftest apt-sources-list-test-change-options ()
  (with-apt-sources-list "deb http://deb.test/ stable main"
    (type "C-c C-o arch=amd64 RET")
    (should-equal-buffer "deb [arch=amd64] http://deb.test/ stable main")
    (type "C-c C-o SPC lang=en RET")
    (should-equal-buffer
     "deb [arch=amd64 lang=en] http://deb.test/ stable main")
    (type "C-c C-o M-0 C-k RET")
    (should-equal-buffer "deb http://deb.test/ stable main")))

(ert-deftest apt-sources-list-test-change-url ()
  (with-apt-sources-list "deb http://deb.test/debian stable main"
    (type "C-c C-u M-0 C-k ftp://deb2.test/debian2 RET")
    (should-equal-buffer "deb ftp://deb2.test/debian2 stable main")))

(ert-deftest apt-sources-list-test-change-suite ()
  (with-apt-sources-list "deb http://deb.test/debian stable main # foo"
    (type "C-c C-s path/ RET")
    (should-equal-buffer "deb http://deb.test/debian path/ # foo")
    (type "C-c C-s unstable RET M-0 C-k xxx RET")
    (should-equal-buffer "deb http://deb.test/debian unstable xxx # foo")
    (type "C-c C-s stable RET")
    (should-equal-buffer "deb http://deb.test/debian stable xxx # foo")))

(ert-deftest apt-sources-list-test-change-components ()
  (with-apt-sources-list "deb http://deb.test/debian stable main # foo"
    (type "C-c C-c M-0 C-k a SPC b")
    (should-equal-buffer "deb http://deb.test/debian stable a b # foo")))

(ert-deftest apt-sources-list-test-motion ()
  (with-apt-sources-list
      "deb [arch=armel] http://deb.test/debian stable main
# comment
deb invalid line
deb http://deb.test/debian stable main"
    (type "C-M-n")
    (should-be-at-line 4)
    (type "C-u - 1 C-M-n")
    (should-be-at-line 1)
    (type "C-u - 1 C-M-p")
    (should-be-at-line 4)
    (type "C-M-p")
    (should-be-at-line 1)

    (should-error (type "C-M-p"))
    (should-error (type "C-u 2 C-M-n"))))

(ert-deftest apt-sources-list-test-font-lock ()
  (with-apt-sources-list
      "deb [arch=armel] http://deb.test/debian stable main # bar"
    (font-lock-ensure)
    (should-use-face 'apt-sources-list-type)
    (search-forward "arch")
    (should-use-face 'apt-sources-list-options)
    (search-forward "http")
    (should-use-face 'apt-sources-list-uri)
    (search-forward "stabl")
    (should-use-face 'apt-sources-list-suite)
    (search-forward "mai")
    (should-use-face 'apt-sources-list-components)
    (search-forward "#")
    (should-use-face 'font-lock-comment-delimiter-face)
    (search-forward "b")
    (should-use-face 'font-lock-comment-face)))


;;; apt-sources-list-test.el ends here
