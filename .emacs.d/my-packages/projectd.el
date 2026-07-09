;;; projectd.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-

(require 'cl-lib)

(use-package project
  :config
  (setq project-vc-extra-root-markers '("Package.swift" "go.mod" "composer.json" "tsconfig.json" "package.json"))
  (setq known-project-locations
        (let ((config-path (expand-file-name ".known-project-locations.el" user-emacs-directory)))
          (if (file-exists-p config-path)
              (with-temp-buffer
                (insert-file-contents config-path)
                (read (buffer-string)))
            (with-temp-buffer
              (insert "()")
              (write-file config-path nil)
              '()))))

  (defun my/project-directories ()
    "Return immediate child directories from `known-project-locations'."
    (cl-loop for root in known-project-locations
             when (file-directory-p root)
             append (cl-remove-if-not
                     #'file-directory-p
                     (directory-files root t directory-files-no-dot-files-regexp))
             into directories
             finally return (sort (delete-dups directories) #'string-lessp)))

  (defun projectd-switch-to-project ()
    "Switch to a project from `known-project-locations'."
    (interactive)
    (let ((selected-project
           (completing-read "Switch to a project: " (my/project-directories) nil t)))
      (when (and (not (string-empty-p selected-project))
                 (file-directory-p selected-project))
        (project-remember-project (project-current t selected-project))
        (dired selected-project))))

  (define-key project-prefix-map (kbd "p") #'projectd-switch-to-project)

  (defun projectd-rgrep-project (&optional args)
    "Run `rgrep' in current project, use project root as default directory"
    (interactive "p")
    (let* ((regexp (grep-read-regexp))
           (project (project-current))
           (default-directory (project-root project))
           (files (grep-read-files regexp))
           (dir (read-directory-name "Base directory: "
					                 nil default-directory t)))
      (setq-local grep-find-template (format "rg -nH --no-heading -g %s -e <R> <D>" (regexp-quote files)))
      (rgrep regexp files dir)))

  (defun projectd-find-file-project (&optional args)
    "Run 'find-file' in current project"
    (interactive "p")
    (let* ((project (project-current))
           (filename (buffer-file-name)))
      (if project
          (call-interactively 'project-find-file)
        (call-interactively 'find-file))))

  (defun projectd-find-file-fuzzy (&optional args)
    "Run 'consult-find' in current project for fuzzy file matching"
    (interactive "p")
    (let* ((project (project-current)))
      (if project
          (let ((default-directory (project-root project)))
            (call-interactively 'consult-fd))
        (call-interactively 'consult-find))))

  ;; (global-set-key (kbd "C-c g") #'projectd-rgrep-project)
  ;; Keep `C-c f` as project.el's UI.
  (setq project-switch-commands
        '((project-find-file "Find file")
          (project-find-dir "Find dir")
          (consult-ripgrep "Ripgrep")
          (project-dired "Dired")
          (magit-project-status "Magit")
          (project-eshell "Eshell")))
  (global-set-key (kbd "C-c f") #'projectd-find-file-project)
  (global-set-key (kbd "C-c F") #'projectd-find-file-fuzzy))

(use-package consult
  :defer t
  :bind (("C-c g" . consult-ripgrep)
         ("C-c b" . consult-buffer)
         ("C-c y" . consult-yank-pop)
         ("M-s l" . consult-line)
         ("M-s i" . consult-imenu))
  :config
  ;; For `consult-fd` (used by `C-c F`), include .gitignore'd files too.
  (setq consult-fd-args
        '((if (executable-find "fdfind" 'remote) "fdfind" "fd")
          "--full-path --color=never --hidden --no-ignore --exclude .git"))
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)
  (advice-add 'register-preview :override #'consult-register-window))

(setq xref-show-xrefs-function #'consult-xref
      xref-show-definitions-function #'consult-xref)

(use-package embark
  :defer t
  :bind (("C-." . embark-act)
         ("C-c ." . embark-dwim)
         ("C-h B" . embark-bindings)))

(use-package embark-consult
  :after (embark consult)
  :defer t
  :bind (("C-c e" . embark-export)))

(provide 'projectd)
