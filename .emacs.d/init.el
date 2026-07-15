;;; init.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-
(require 'package)
(package-initialize)

(setq use-package-always-ensure t)

(add-to-list 'load-path (concat user-emacs-directory "my-packages/"))
(require 'unfuck)
(require 'theme)
(require 'projectd)
(require 'prog)
(require 'autocomplete)
(require 'lsp)
(require 'phpd)

(defun adjust-font-height (delta)
  (let* ((current-height (face-attribute 'default :height))
         (new-height (+ current-height delta)))
    (set-face-attribute 'default nil :height new-height)))

(global-set-key (kbd "M-=") (lambda ()
                              (interactive)
                              (adjust-font-height 10)))
(global-set-key (kbd "M--") (lambda ()
                              (interactive)
                              (adjust-font-height -10)))

(global-set-key (kbd "M-n") #'next-error)
(global-set-key (kbd "M-p") #'previous-error)

(use-package expand-region
  :bind (("C-=" . er/expand-region)
         ("C--" . er/contract-region)))

(defun my/copy-file-path-to-clipboard ()
  "Copy current file path to clipboard.
   If inside a project, copy relative path to project root; otherwise, copy absolute path."
  (interactive)
  (let* ((file-path (buffer-file-name))
         (project-root-path (when (project-current)
                                (project-root (project-current))))
         (path-to-copy nil))
    (cond
     ((null file-path)
      (message "No file is being visited in this buffer."))
     ((and project-root-path (file-in-directory-p file-path project-root-path))
      ;; File is in a project, copy relative path
      (setq path-to-copy (file-relative-name file-path project-root-path)))
     (t
      ;; Not in a project or file not within project root, copy absolute path
      (setq path-to-copy file-path)))

    (when path-to-copy
      (message path-to-copy)
      (kill-new path-to-copy)
      (message "Copied: %s" path-to-copy))))

(global-set-key (kbd "C-c C-c") #'my/copy-file-path-to-clipboard)

(defun my/scroll-down()
  (interactive)
  (next-line 15)
  (recenter))

(defun my/scroll-up()
  (interactive)
  (previous-line 15)
  (recenter))

(global-set-key (kbd "M-<down>") #'my/scroll-down)
(global-set-key (kbd "M-<up>") #'my/scroll-up)

(setopt grep-command "rg -nH --no-heading -e ")

(when (daemonp)
  (use-package exec-path-from-shell
    :ensure t
    :commands exec-path-from-shell-initialize
    :init
    ;; ~600ms+ saved on daemon startup; PATH is applied before first idle work.
    (add-hook 'after-init-hook
              (lambda ()
                (run-with-idle-timer 0 nil #'exec-path-from-shell-initialize)))))

(with-eval-after-load 'undo-tree
  (defun my/undo-tree-silence (orig-fun &rest args)
    (let ((inhibit-message t))
      (apply orig-fun args)))
  (advice-add 'undo-tree-load-history :around #'my/undo-tree-silence))

(use-package undo-tree
  ;; Undo-tree is not compatible with Dired buffers on current Emacs builds.
  ;; Enable it only for buffers that visit files, rather than globally.
  :hook (find-file . undo-tree-mode)
  :init
  (setq undo-tree-history-directory-alist `(("." . ,(concat user-emacs-directory "undo/")))))

(use-package magit
  ;; Load shortly after startup so opening the first status buffer is responsive.
  :defer 1)

(use-package wgrep
  :defer t
  :config
  (setq wgrep-auto-save-buffer t))

(use-package multiple-cursors
  :defer t
  :bind ("M-d" . mc/mark-next-like-this))

(use-package avy
  :defer t
  :bind ("C-;" . avy-goto-char-timer)
  :custom (avy-timeout-seconds 0.1))

(use-package which-key
  :defer 1
  :config
  (which-key-mode 1))
