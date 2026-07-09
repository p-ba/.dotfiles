;;; theme.el --- ui -*- no-byte-compile: t; lexical-binding: t; -*-

(set-face-attribute 'default nil
                    :family "Maple Mono NF"
                    :height 190
                    :weight 'normal)

(set-face-attribute 'fixed-pitch nil
                    :family "JetbrainsMono Nerd Font"
                    :inherit 'default
                    :height 0.9
                    :weight 'normal)

(setq-default line-spacing 0.19)

(defun current-file-display-name ()
  (let* ((file-path (buffer-file-name))
         (project-root-path (when (project-current)
                                 (project-root (project-current))))
         (path-to-copy nil))
    (cond
     ((null file-path)
      path-to-copy "")
     ((and project-root-path (file-in-directory-p file-path project-root-path))
      ;; File is in a project, show relative path
      (setq path-to-copy (file-relative-name file-path project-root-path)))
     (t
      ;; Not in a project or file not within project root, show absolute path
      (setq path-to-copy buffer-file-truename)))

    path-to-copy))

(defun current-vc-branch-display-name ()
  "Return the current VC branch name, if available."
  (when (and vc-mode (stringp vc-mode))
    (string-trim (replace-regexp-in-string "^ Git[:-]" "" vc-mode))))

(define-key mode-line-major-mode-keymap [header-line]
            (lookup-key mode-line-major-mode-keymap [mode-line]))

(defun mode-line-render (left right)
  (let* ((available-width (- (window-width) (length left) )))
    (format (format "%%s %%%ds" available-width) left right)))

(setq-default mode-line-format
     '((:eval
       (mode-line-render
        (format-mode-line (list
         (propertize " ☰" 'face `(:inherit mode-line-buffer-id)
                         'help-echo "Mode(s) menu"
                         'mouse-face 'mode-line-highlight
                         'local-map   mode-line-major-mode-keymap)
          " " (current-file-display-name)
          (if (and buffer-file-name (buffer-modified-p))
              (propertize " (modified)" 'face `()))))
        (format-mode-line
         (list
          (when-let ((branch (current-vc-branch-display-name)))
            (propertize (format "%s  " branch) 'face 'mode-line-emphasis))
          mode-name
          (propertize "  %4l:%2c  " 'face `())))))))

(setq default-frame-alist
      (append (list '(width  . 72) '(height . 40)
                    '(vertical-scroll-bars . nil)
                    '(internal-border-width . 0)
                    '(ns-transparent-titlebar . t))))

(set-frame-parameter (selected-frame)
                     'internal-border-width 0)

(fringe-mode '(0 . 0))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

;; (use-package doric-themes
;;   :ensure t
;;   :demand t
;;   :config
;;   ;; These are the default values.
;;   (setq doric-themes-to-toggle '(doric-light doric-water))
;;   (setq doric-themes-to-rotate doric-themes-collection)
;; 
;;   ;; (doric-themes-select 'doric-water))
;;   )

(use-package kaolin-themes
  :config
  (load-theme 'kaolin-dark t)
  (kaolin-treemacs-theme))

(defun setup-transparency()
  ;; Transparency
  (dolist (frm (frame-list))
    (when (eq system-type 'darwin)
      (set-frame-parameter frm 'alpha '(95 95)))
    (set-frame-parameter frm 'alpha-background 95))

  (unless (display-graphic-p (selected-frame))
    (send-string-to-terminal
     (format "\033]11;[90]%s\033\\"
             (face-attribute 'default :background)))
    (set-face-background 'default "unspecified-bg" (selected-frame))
    (set-face-background 'line-number "unspecified-bg" (selected-frame))
    (set-face-background 'line-number-current-line "unspecified-bg" (selected-frame))))

(setup-transparency)

(add-hook 'server-after-make-frame-hook #'setup-transparency)
(add-hook 'server-switch-hook #'setup-transparency)

(setq window-divider-default-right-width 12
      window-divider-default-places 'right-only)

(provide 'theme)
