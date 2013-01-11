(require 'lisp-mnt)

(defun write-readme (commentary dir)
  (with-current-buffer (find-file-noselect (format "%s/README" dir))
    (insert commentary)
    (goto-char (point-min))
    (save-excursion
      (when (re-search-forward "^;;; Commentary:\n" nil t)
        (replace-match ""))
      (when (re-search-forward "^\\(;;;\\) .*\\(\n\\)" nil t)
        (replace-match "==" nil t nil 1)
        (replace-match " ==\n" nil t nil 2))
      (goto-char (point-min))
      (while (re-search-forward "^\\(;; ?\\)" nil t)
        (replace-match ""))
      (goto-char (point-min))
      (when (re-search-forward "\\`\\( *\n\\)+" nil t)
        (replace-match "")))
    (delete-trailing-whitespace)
    (save-buffer 0)))

(defun build ()
  (with-current-buffer (find-file-noselect "robe.el")
    (ignore-errors (make-directory "build"))
    (let* ((name "robe")
           (version (lm-version))
           (summary (lm-summary))
           (depends (lm-header "package-requires"))
           (commentary (lm-commentary))
           (default-directory (concat default-directory "build/"))
           (dir (format "%s-%s" name version)))
      (when (file-exists-p dir)
        (delete-directory dir t))
      (make-directory dir)
      (dolist (file (directory-files ".." t (format "%s.*\\.el\\'" name)))
        (copy-file file dir))
      (copy-directory "../lib" dir)
      (write-readme commentary dir)
      (with-temp-buffer
        (insert (format "(define-package \"%s\" \"%s\"\n  \"%s\"\n  '%s)"
                        name version summary depends))
        (write-region (point-min) (point-max)
                      (format "%s/%s-pkg.el" dir name)))
      (call-process "tar" nil "*robe-build*" nil "-cvf"
                    (format "%s.tar" dir) dir))))
