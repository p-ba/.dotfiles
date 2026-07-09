;;; dumb-import.el --- Import PHP symbols automatically -*- lexical-binding: t; -*-

;;; Commentary:

;; This package provides functionality to import PHP symbols (Classes, Traits,
;; Interfaces, Enums, and functions) automatically.  It allows the user to
;; import the symbol under the cursor or enter a symbol name manually.
;; The package searches all PHP files for the symbol definition and adds
;; a "use SymbolName;" statement at the top of the file.
;;
;; Installation:
;;
;; Make sure the file is in your load-path and add:
;;   (require 'dumb-import)
;; to your init.el file.
;;
;; Usage:
;;
;; When editing PHP files, you can use the following commands:
;;
;; - `dumb-import-symbol-at-point' (C-c i): Import the PHP symbol at point.
;;   This will search for the symbol definition in your project and add
;;   a "use" statement for it.
;;
;; - `dumb-import-symbol' (C-c C-i): Manually enter a PHP symbol to import.
;;   This will prompt you for a symbol name, search for its definition,
;;   and add a "use" statement for it.
;;
;; - `dumb-import-sort-use-statements' (C-c s): Sort all use statements in the current
;;   buffer alphabetically. This is automatically called when adding a new
;;   use statement, but can also be called manually.
;;
;; You can also access these commands from the PHP menu under "Import".
;;
;; Customization:
;;
;; - `dumb-import-php-project-root': Set the root directory of your PHP project.
;;   If nil, the current directory will be used.
;;
;; - `dumb-import-php-file-extensions': List of PHP file extensions to search.
;;   Default is ("php").
;;
;; - `dumb-import-insert-position': Position to insert the use statement.
;;   Can be 'after-namespace, 'after-opening-tag, or 'before-class.

;;; Code:

(require 'cl-lib)
(require 'thingatpt)

(defgroup dumb-import nil
  "Import PHP symbols automatically."
  :group 'languages
  :prefix "dumb-import-")

(defcustom dumb-import-php-project-root nil
  "Root directory of the PHP project.
If nil, the current directory will be used."
  :type '(choice (directory :tag "Directory")
                 (const :tag "Use current directory" nil))
  :group 'dumb-import)

(defcustom dumb-import-php-file-extensions '("php")
  "List of PHP file extensions to search for symbol definitions."
  :type '(repeat string)
  :group 'dumb-import)

(defcustom dumb-import-insert-position 'after-namespace
  "Position to insert the use statement.
Can be one of:
- 'after-namespace: Insert after the namespace declaration
- 'after-opening-tag: Insert after the opening PHP tag
- 'before-class: Insert before the class/trait/interface declaration"
  :type '(choice (const :tag "After namespace declaration" after-namespace)
                 (const :tag "After opening PHP tag" after-opening-tag)
                 (const :tag "Before class declaration" before-class))
  :group 'dumb-import)

(defun dumb-import-get-project-root ()
  "Get the PHP project root directory.
If there's an active project, use its root directory.
Otherwise, use `dumb-import-php-project-root` or `default-directory`."
  (or (when (project-current)
        (project-root (project-current)))
      dumb-import-php-project-root
      default-directory))

(defun dumb-import-find-php-files (symbol)
  "Find all PHP files in the project that might contain SYMBOL.
If SYMBOL is provided, only returns files that contain the symbol."
  (let ((project-root (dumb-import-get-project-root))
        (file-list nil))
    (dolist (ext dumb-import-php-file-extensions)
      (let* ((cmd (format "fd -t f -I -e %s -g '%s.%s' %s"
                          ext
                          symbol
                          ext
                          (shell-quote-argument project-root))))
        (setq file-list (append file-list
                                (split-string (shell-command-to-string cmd) "\n" t)))))
    file-list))

(defun dumb-import-find-symbol-definition (symbol)
  "Find the definition of SYMBOL in PHP files.
Returns a list of (file-path fully-qualified-name) for each match."
  (let ((files (dumb-import-find-php-files symbol))  ; Pass symbol to filter files
        (results nil))
    (dolist (file files)
      (with-temp-buffer
        (insert-file-contents file)
        ;; Look for class, trait, interface, enum definitions
        (goto-char (point-min))
        (while (re-search-forward
                (concat "^\\s-*\\(class\\|trait\\|interface\\|enum\\)\\s-+\\("
                        (regexp-quote symbol)
                        "\\)\\b") nil t)
          (save-excursion
            (message file)
            (goto-char (point-min))
            (let ((namespace ""))
              (when (re-search-forward "^\\s-*namespace\\s-+\\([^;]+\\);" nil t)
                (setq namespace (match-string-no-properties 1)))
              (push (list file
                          (if (string= namespace "")
                              symbol
                            (concat namespace "\\" symbol)))
                    results))))

        ;; Look for function definitions
        (goto-char (point-min))
        (while (re-search-forward
                (concat "^\\s-*function\\s-+\\("
                        (regexp-quote symbol)
                        "\\)\\s-*(") nil t)
          (save-excursion
            (goto-char (point-min))
            (let ((namespace ""))
              (when (re-search-forward "^\\s-*namespace\\s-+\\([^;]+\\);" nil t)
                (setq namespace (match-string-no-properties 1)))
              (push (list file
                          (if (string= namespace "")
                              symbol
                            (concat namespace "\\" symbol)))
                    results))))))
    results))

(defun dumb-import-get-symbol-at-point ()
  "Get the PHP symbol at point."
  (let ((symbol (thing-at-point 'symbol)))
    (when symbol
      (substring-no-properties symbol))))

(defun dumb-import-find-insert-position ()
  "Find the position to insert the use statement."
  (save-excursion
    (goto-char (point-min))
    (cond
     ;; After namespace declaration
     ((and (eq dumb-import-insert-position 'after-namespace)
           (re-search-forward "^\\s-*namespace\\s-+[^;]+;" nil t))
      (forward-line 1)
      (point))

     ;; After opening PHP tag
     ((and (eq dumb-import-insert-position 'after-opening-tag)
           (re-search-forward "^<\\?php" nil t))
      (forward-line 1)
      (point))

     ;; Before class declaration
     ((and (eq dumb-import-insert-position 'before-class)
           (re-search-forward "^\\s-*\\(class\\|trait\\|interface\\|enum\\)\\s-+" nil t))
      (beginning-of-line)
      (point))

     ;; Default: beginning of file after opening tag
     (t
      (goto-char (point-min))
      (when (re-search-forward "^<\\?php" nil t)
        (forward-line 1))
      (point)))))

(defun dumb-import-sort-use-statements ()
  "Sort top-level use statements in the current buffer alphabetically.
Only sorts use statements that appear before any class/trait/interface/enum definition."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((use-statements nil)
          (start-pos nil)
          (end-pos nil)
          (class-pos nil))

      ;; Find the position of the first class/trait/interface/enum definition
      (save-excursion
        (goto-char (point-min))
        (when (re-search-forward "^\\s-*\\(class\\|trait\\|interface\\|enum\\)\\s-+" nil t)
          (setq class-pos (match-beginning 0))))

      ;; Find all top-level use statements (before any class/trait/interface/enum definition)
      (while (re-search-forward "^\\s-*use\\s-+\\([^;]+\\);" nil t)
        ;; Only process use statements that appear before the first class definition
        ;; or process all if no class definition was found
        (when (or (not class-pos) (< (point) class-pos))
          (let ((stmt (match-string-no-properties 0))
                (name (match-string-no-properties 1)))
            (push (cons name stmt) use-statements)
            (unless start-pos
              (setq start-pos (line-beginning-position)))
            (setq end-pos (line-end-position)))))

      ;; Sort and replace if we found any
      (when (and start-pos end-pos use-statements)
        (delete-region start-pos end-pos)
        (goto-char start-pos)
        (insert "\n")
        (dolist (stmt (sort use-statements (lambda (a b) (string< (car a) (car b)))))
          (insert (cdr stmt) "\n"))
        (message "Sorted %d use statements" (length use-statements))))))

(defun dumb-import-add-use-statement (fully-qualified-name)
  "Add a use statement for FULLY-QUALIFIED-NAME to the current buffer."
  (save-excursion
    (let ((insert-pos (dumb-import-find-insert-position))
          (use-statement (format "use %s;" fully-qualified-name)))

      ;; Check if the use statement already exists
      (goto-char (point-min))
      (if (re-search-forward (concat "^\\s-*use\\s-+"
                                     (regexp-quote fully-qualified-name)
                                     "\\s-*;") nil t)
          (message "Use statement for %s already exists" fully-qualified-name)

        ;; Insert the use statement
        (goto-char insert-pos)
        (if (looking-at "^\\s-*$")
            (insert use-statement)
          (insert use-statement "\n"))
        (message "Added use statement: %s" use-statement)

        ;; Sort use statements
        (dumb-import-sort-use-statements)))))

;;;###autoload
(defun dumb-import-symbol-at-point ()
  "Import the PHP symbol at point."
  (interactive)
  (let ((symbol (dumb-import-get-symbol-at-point)))
    (if (not symbol)
        (message "No symbol at point")
      (dumb-import-symbol symbol))))

;;;###autoload
(defun dumb-import-symbol (symbol)
  "Import the PHP SYMBOL.
If called interactively, prompt for the symbol name."
  (interactive "sEnter PHP symbol to import: ")
  (let ((definitions (dumb-import-find-symbol-definition symbol)))
    (cond
     ((null definitions)
      (message "No definition found for symbol: %s" symbol))

     ((= (length definitions) 1)
      (dumb-import-add-use-statement (cadr (car definitions))))

     (t
      (let* ((options (mapcar (lambda (def)
                                (cons (format "%s (%s)" (cadr def) (car def))
                                      (cadr def)))
                              definitions))
             (choice (completing-read "Multiple definitions found, choose one: "
                                      options nil t)))
        (dumb-import-add-use-statement (cdr (assoc choice options))))))))

;;;###autoload
(defun dumb-import-setup-keybindings ()
  "Set up keybindings for dumb-import in PHP mode."
  (local-set-key (kbd "C-c i") 'dumb-import-symbol-at-point)
  (local-set-key (kbd "C-c C-i") 'dumb-import-symbol)
  (local-set-key (kbd "C-c s") 'dumb-import-sort-use-statements))

;; Add hook to php-mode to set up keybindings
(add-hook 'php-mode-hook 'dumb-import-setup-keybindings)

(provide 'dumb-import)
;;; dumb-import.el ends here
