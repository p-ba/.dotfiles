;;; unfuck.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-
;; No startup  screen
(setq inhibit-startup-screen t)

;; No startup message
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message t)

;; No message in scratch buffer
(setq initial-scratch-message nil)

;; Initial buffer
(setq initial-buffer-choice nil)

;; No frame title
(setq frame-title-format nil)

;; No file dialog
(setq use-file-dialog nil)

;; No dialog box
(setq use-dialog-box nil)

;; No popup windows
;; (setq pop-up-windows nil)

;; Prefer vertical splits over horizontal ones
(setq split-width-threshold 140
      split-height-threshold nil)

;; No empty line indicators
(setq indicate-empty-lines nil)

;; No cursor in inactive windows
(setq cursor-in-non-selected-windows nil)

;; Initial buffer: keep `fundamental-mode' (see early-init.el) — avoids loading
;; text-mode hooks during startup. New buffers still default to text-mode.
(setq initial-major-mode 'fundamental-mode)
(setq default-major-mode 'text-mode)

;; Turn on relative line numbers
(setq display-line-numbers-type 'relative)

(defun my/prog-mode-display-line-numbers ()
  "Enable line numbers after the current programming buffer is displayed."
  (let ((buffer (current-buffer)))
    (run-with-idle-timer
     0.05 nil
     (lambda ()
       (when (buffer-live-p buffer)
         (with-current-buffer buffer
           (when (derived-mode-p 'prog-mode)
             (display-line-numbers-mode 1))))))))

(add-hook 'prog-mode-hook #'my/prog-mode-display-line-numbers)

;; Moderate font lock
;; (setq font-lock-maximum-decoration nil)

;; No limit on font lock
;; (setq font-lock-maximum-size nil)

;; No line break space points
(setq auto-fill-mode nil)

;; Fill column at 120
(setq fill-column 120)

;; No confirmation for visiting non-existent files
(setq confirm-nonexistent-file-or-buffer nil)

;; Completion style, see
;; gnu.org/software/emacs/manual/html_node/emacs/Completion-Styles.html
;; Note: completion-styles configured in autocomplete.el with orderless

;; For icomplete it is necessary to use a hook to configure the
;; completion-styles variable correctly!
(add-hook 'icomplete-minibuffer-setup-hook
          (lambda () (kill-local-variable 'completion-styles)))

(setq completion-preview-minimum-symbol-length 3)

;; (global-completion-preview-mode)
;; (define-key completion-preview-active-mode-map (kbd "M-n") #'completion-preview-next-candidate)
;; (define-key completion-preview-active-mode-map (kbd "M-p") #'completion-preview-prev-candidate)

(setq completion-auto-help nil)
(setq completions-detailed t)

;; Use RET to open org-mode links, including those in quick-help.org
(setq org-return-follows-link t)

;; Mouse active in terminal
(unless (display-graphic-p)
  (xterm-mouse-mode 1)
  (global-set-key (kbd "<mouse-4>") 'scroll-down-line)
  (global-set-key (kbd "<mouse-5>") 'scroll-up-line))

;; Mac specific
(when (eq system-type 'darwin)
  (setq ns-use-native-fullscreen t
        mac-option-key-is-meta nil
        mac-command-key-is-meta t
        mac-command-modifier 'meta
        mac-option-modifier 'super
        mac-use-title-bar nil))

;; Make sure clipboard works properly in tty mode on OSX
(defun copy-from-osx ()
  (shell-command-to-string "pbpaste"))
(defun paste-to-osx (text &optional push)
  (let ((process-connection-type nil))
    (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
      (process-send-string proc text)
      (process-send-eof proc))))
(when (and (not (display-graphic-p))
           (eq system-type 'darwin))
    (setq interprogram-cut-function 'paste-to-osx)
    (setq interprogram-paste-function 'copy-from-osx))

;; y/n for  answering yes/no questions
(fset 'yes-or-no-p 'y-or-n-p)
(setq use-short-answers t)

;; Modern built-ins that improve interaction without changing core workflows.
(repeat-mode 1)
(pixel-scroll-precision-mode 1)
(delete-selection-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)
(global-hl-line-mode 1)
(minibuffer-depth-indicate-mode 1)

;; No tabs
(setq-default indent-tabs-mode nil)

;; Tab.space equivalence
(setq-default tab-width 4)

;; Auto-indent
(electric-indent-mode 1)

;; Better jumps
(global-superword-mode t)

;; Size of temporary buffers
(temp-buffer-resize-mode)
(setq temp-buffer-max-height 8)

;; Minimum window height
(setq window-min-height 1)

(setq display-line-numbers-width 3)
(setq scroll-margin 5)
(setq scroll-conservatively 101)

(setq line-spacing 2)

;; Buffer encoding
(prefer-coding-system       'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-language-environment   'utf-8)

;; Unique buffer names
(require 'uniquify)
(setq uniquify-buffer-name-style 'reverse
      uniquify-separator " • "
      uniquify-after-kill-buffer-p t
      uniquify-ignore-buffers-re "^\\*")

;; Kill term buffer when exiting.
(defun my/term-sentinel-kill-buffer (orig-fun proc msg)
  (if (memq (process-status proc) '(signal exit))
      (let ((buffer (process-buffer proc)))
        (funcall orig-fun proc msg)
        (when (buffer-live-p buffer)
          (kill-buffer buffer)))
    (funcall orig-fun proc msg)))

(advice-add 'term-sentinel :around #'my/term-sentinel-kill-buffer)

;; Start maximized
(add-hook 'window-setup-hook 'toggle-frame-maximized t)
(add-hook 'server-after-make-frame-hook 'toggle-frame-maximized t)
(add-hook 'server-switch-hook 'toggle-frame-maximized t)

;;; Auto revert
;; Auto-revert in Emacs is a feature that automatically updates the contents of
;; a buffer to reflect changes made to the underlying file.
(setq revert-without-query (list ".")  ; Do not prompt
      auto-revert-stop-on-user-input nil
      auto-revert-verbose t)

;; Revert other buffers (e.g, Dired)
(setq global-auto-revert-non-file-buffers t)
(setq global-auto-revert-ignore-modes '(Buffer-menu-mode))
(global-auto-revert-mode 1)

;; Avoid backups or lockfiles to prevent creating world-readable copies of files
(setq create-lockfiles nil)
(setq make-backup-files nil)

(setq save-files-directory (expand-file-name "backups/" user-emacs-directory)
 auto-save-file-name-transforms `((".*" ,save-files-directory t))
 backup-directory-alist `(("." . ,save-files-directory)))
(setq tramp-backup-directory-alist backup-directory-alist)
(setq backup-by-copying-when-linked t)
(setq backup-by-copying t)  ; Backup by copying rather renaming
(setq delete-old-versions t)  ; Delete excess backup versions silently
(setq version-control t)  ; Use version numbers for backup files
(setq kept-new-versions 5)
(setq kept-old-versions 5)

;;; Auto save

;; Enable auto-save to safeguard against crashes or data loss. The
;; `recover-file' or `recover-session' functions can be used to restore
;; auto-saved data.
(setq auto-save-default nil)
(setq auto-save-no-message t)

;; Do not auto-disable auto-save after deleting large chunks of
;; text.
(setq auto-save-include-big-deletions t)

(setq auto-save-list-file-prefix
      (expand-file-name "autosave/" user-emacs-directory))
(setq tramp-auto-save-directory
      (expand-file-name "tramp-autosave/" user-emacs-directory))

;;; recentf

;; `recentf' is an that maintains a list of recently accessed files.
(setq recentf-max-saved-items 300) ; default is 20
(setq recentf-max-menu-items 15)
(setq recentf-auto-cleanup (if (daemonp) 300 'never))
;; Update recentf-exclude
(setq recentf-exclude (list "^/\\(?:ssh\\|su\\|sudo\\)?:"))
(recentf-mode)

;;; saveplace

;; Enables Emacs to remember the last location within a file upon reopening.
(setq save-place-file (expand-file-name "saveplace" user-emacs-directory))
(setq save-place-limit 600)
(save-place-mode)
;;; savehist

;; `savehist-mode' is an Emacs feature that preserves the minibuffer history
;; between sessions.
(setq history-length 300)
(setq savehist-save-minibuffer-history t)  ;; Default
(setq savehist-additional-variables
      '(kill-ring                        ; clipboard
        register-alist                   ; macros
        mark-ring global-mark-ring       ; marks
        search-ring regexp-search-ring)) ; searches
(savehist-mode)

;;; Text editing, indent, font, and formatting

;; Avoid automatic frame resizing when adjusting settings.
(setq global-text-scale-adjust-resizes-frames nil)

;; A longer delay can be annoying as it causes a noticeable pause after each
;; deletion, disrupting the flow of editing.
(setq delete-pair-blink-delay 0.03)

(setq-default left-fringe-width  8)
(setq-default right-fringe-width 8)

;; Do not show an arrow at the top/bottomin the fringe and empty lines
(setq-default indicate-buffer-boundaries nil)
(setq-default indicate-empty-lines nil)

;; Enable indentation and completion using the TAB key
(setq tab-always-indent 'complete)
(setq tab-first-completion 'word-or-paren-or-punct)

;; Perf: Reduce command completion overhead.
(setq read-extended-command-predicate #'command-completion-default-include-p)

;; Enable multi-line commenting which ensures that `comment-indent-new-line'
;; properly continues comments onto new lines.
(setq comment-multi-line t)

;; Ensures that empty lines within the commented region are also commented out.
;; This prevents unintended visual gaps and maintains a consistent appearance.
(setq comment-empty-lines t)

;; Eliminate delay before highlighting search matches
(setq lazy-highlight-initial-delay 0)

;;; Eglot

;; A setting of nil or 0 means Eglot will not block the UI at all, allowing
;; Emacs to remain fully responsive, although LSP features will only become
;; available once the connection is established in the background.
(setq eglot-sync-connect 0)

(setq eglot-autoshutdown t)  ; Shut down server after killing last managed buffer

;; Activate Eglot in cross-referenced non-project files
(setq eglot-extend-to-xref t)

;;; icomplete

;; Do not delay displaying completion candidates in `fido-mode' or
;; `fido-vertical-mode'
(setq icomplete-compute-delay 0.01)

;; No beeping or blinking
(setq visible-bell nil)
(setq ring-bell-function #'ignore)

(setq resize-mini-windows 'grow-only
      read-answer-short t)

(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

(setq scroll-preserve-screen-position t)
(setq custom-file (expand-file-name "init-custom.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)

;; Show the option to show diff of the file when using C-x s or C-x C-c
(add-to-list 'save-some-buffers-action-alist
               (list "d"
                     (lambda (buffer) (diff-buffer-with-file (buffer-file-name buffer)))
                     "show diff between the buffer and its file"))

;; Remove training whitespaces and final newline
;; (add-hook 'before-save-hook 'delete-trailing-whitespace)
(setq require-final-newline t)

;; Repeat mark pop until there's visible motion detected
(setq set-mark-command-repeat-pop t)
(advice-add 'pop-to-mark-command :around
            (lambda (pop-to-mark &rest args)
              (let ((p (point)))
                (dotimes (_ 5)
                  (when (= p (point))
                    (apply pop-to-mark args))))))

;; Enable recursive minibuffers
(setq enable-recursive-minibuffers t)

(require 'ls-lisp)
(setq ls-lisp-dirs-first t)
(setq ls-lisp-use-insert-directory-program nil)

(with-eval-after-load "dired"
  ;;(setq dired-listing-switches "-alh")
  (setq dired-omit-files "^\\.git$\\|^\\.vscode\\|^\\.idea")
  (setq dired-recursive-copies 'always)
  (setq dired-auto-revert-buffer t)
  (setf dired-kill-when-opening-new-dired-buffer t)
  (add-hook 'dired-mode-hook (lambda () (dired-omit-mode 1))))

(with-eval-after-load "eshell"
  (defun eshell-pick-history ()
    "Show Eshell history combining memory and file persistence."
    (interactive)
    ;; Write current session's history to file so it's always fresh
    (when (bound-and-true-p eshell-history-ring)
      (eshell-write-history))
    ;; Then read the history from file
    (let* ((history-file (expand-file-name "eshell/history" user-emacs-directory))
           (history-entries (when (file-exists-p history-file)
                              (with-temp-buffer
                                (insert-file-contents history-file)
                                (split-string (buffer-string) "\n" t))))
           (selection (completing-read "Eshell History: " history-entries)))
      (when selection
        (insert selection))))

  (add-hook 'eshell-mode-hook
            (lambda ()
              (local-set-key (kbd "C-c l") #'eshell-pick-history)
              (local-set-key (kbd "C-l")
                             (lambda ()
                               (interactive)
                               (eshell/clear 1)))))
  ;; GIVES SYNTAX HIGHLIGHTING TO CAT
  ;;
  (defun eshell/cat-with-syntax-highlighting (filename)
    "Like cat(1) but with syntax highlighting.
  Stole from aweshell"
    (let ((existing-buffer (get-file-buffer filename))
          (buffer (find-file-noselect filename)))
      (eshell-print
       (with-current-buffer buffer
         (if (fboundp 'font-lock-ensure)
             (font-lock-ensure)
           (with-no-warnings
             (font-lock-fontify-buffer)))
         (let ((contents (buffer-string)))
           (remove-text-properties 0 (length contents) '(read-only nil) contents)
           contents)))
      (unless existing-buffer
        (kill-buffer buffer))
      nil))
  (advice-add 'eshell/cat :override #'eshell/cat-with-syntax-highlighting))

(provide 'unfuck)
