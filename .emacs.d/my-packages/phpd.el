;;; phpd.el --- php-mode enchantments -*- no-byte-compile: t; lexical-binding: t; -*-

(defun php-get-namespace ()
  (interactive)
  "Determine PHP namespace based on PSR-0/4 autoload info in composer.json."
  (let* ((file (or (buffer-file-name) default-directory))
         (composer-json-path (locate-dominating-file file "composer.json"))
         (json-object-type 'alist)
         (json-array-type 'list)
         (json-key-type 'string)
         (namespace ""))
    (when composer-json-path
      (let* ((composer-json (expand-file-name "composer.json" composer-json-path))
             (data (when (file-exists-p composer-json)
                     (with-temp-buffer
                       (insert-file-contents composer-json)
                       (json-read))))
             (autoload (assoc "autoload" data)))
        (when autoload
          (let ((best-match nil)
                (file-dir (file-relative-name (file-name-directory file) composer-json-path)))
            (dolist (psr (cdr autoload))
              (dolist (entry (cdr psr))
                (let* ((ns (car entry))
                       (dir (file-name-as-directory (cdr entry))))
                  (when (string-prefix-p dir file-dir)
                    (when (or (not best-match)
                              (> (length dir) (length (cdr best-match))))
                      (setq best-match (cons ns dir))))))
              (when best-match
                (let* ((ns-prefix (car best-match))
                       (ns-path (cdr best-match))
                       (relative (file-relative-name (file-name-directory file)
                                                     (expand-file-name ns-path composer-json-path)))
                       (extra-ns (replace-regexp-in-string "/" "\\\\"
                                                           (string-trim-right relative "/"))))
                  (setq namespace (if (string= extra-ns "")
                                      (string-trim-right ns-prefix "\\\\")
                                    (concat (string-trim-right ns-prefix "\\\\") "\\" extra-ns))))))))
        namespace))))

(provide 'phpd)
