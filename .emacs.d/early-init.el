;;; early-init.el --- Early init -*- lexical-binding: t; -*-

(defvar minimal-emacs--backup-gc-cons-threshold gc-cons-threshold
  "Backup of the original value of `gc-cons-threshold' before startup.")

(defvar emacs-debug nil
  "Debug flag")

(defvar emacs-native-comp t
  "Enable natve complilation")

;; Prefer loading newer compiled files
(setq load-prefer-newer t)
(setq debug-on-error emacs-debug)

;; Keep package activation explicit in init.el.
(setq package-enable-at-startup nil)

(setq gc-cons-threshold most-positive-fixnum)

(defvar emacs-gc-cons-threshold (* 128 1024 1024))

(setq garbage-collection-messages emacs-debug)

;;; Minibuffer / completion (`vertico`, `corfu') call `set-local' from GNU ELPA
;;; `compat'.  Emacs bundles a `compat.el' stub without that API, and `:ensure
;;; compat' may not activate the ELPA library in time — define it before init.
(unless (fboundp 'set-local)
  (defun set-local (variable value)
    "Ensure VARIABLE has a buffer-local binding set to VALUE."
    (set (make-local-variable variable) value)))

;;; Native compilation and Byte compilation

(if (and (featurep 'native-compile)
         (fboundp 'native-comp-available-p)
         (native-comp-available-p))
    (when emacs-native-comp
      ;; Activate `native-compile'
      (setq native-comp-deferred-compilation t
            native-comp-jit-compilation t
            package-native-compile t)
      ;; Homebrew Emacs + GCC on Apple silicon: native-comp invokes libgccjit,
      ;; whose linker pull needs GNU `libemutls_w.a`. Without LIBRARY_PATH, ld
      ;; reports `library emutls_w not found`. GUI Emacs often has no PATH set.
      (when (eq system-type 'darwin)
        (let ((gcc (or (executable-find "gcc-15")
                       (executable-find "gcc-14")
                       (executable-find "gcc-13")
                       (let ((brew "/opt/homebrew/bin/gcc-15"))
                         (when (file-executable-p brew) brew)))))
          (when gcc
            (with-temp-buffer
              (when (zerop (call-process gcc nil t nil "-print-file-name=libemutls_w.a"))
                (let* ((full (string-trim (buffer-string)))
                       (dir (and (> (length full) 0)
                                 (not (equal full "libemutls_w.a"))
                                 (file-exists-p full)
                                 (file-name-directory (file-truename full)))))
                  (when dir
                    (setenv "LIBRARY_PATH"
                            (let ((cur (getenv "LIBRARY_PATH")))
                              (if (and cur (> (length cur) 0))
                                  (concat dir ":" cur)
                                dir)))))))))))
  ;; Deactivate the `native-compile' feature if it is not available
  (setq features (delq 'native-compile features)))

(setq native-comp-warning-on-missing-source emacs-debug
      native-comp-async-report-warnings-errors (or emacs-debug 'silent)
      native-comp-verbose (if emacs-debug 1 0))

(setq jka-compr-verbose emacs-debug)
(setq byte-compile-warnings emacs-debug
      byte-compile-verbose emacs-debug)

;;; Miscellaneous

(set-language-environment "UTF-8")

;; Set-language-environment sets default-input-method, which is unwanted.
(setq default-input-method nil)

;; Increase how much is read from processes in a single chunk
(setq read-process-output-max (* 2 1024 1024))  ; 1024kb

(setq process-adaptive-read-buffering nil)

;; Don't ping things that look like domain names.
(setq ffap-machine-p-known 'reject)

(setq warning-minimum-level (if emacs-debug :warning :error))
(setq warning-suppress-types '((lexical-binding)))

(when emacs-debug
  (setq message-log-max 16384))

(defvar file-name-handler-alist-old file-name-handler-alist)

(setq file-name-handler-alist nil)

(defun after-init()
  (setq file-name-handler-alist file-name-handler-alist-old)
  (setq	gc-cons-threshold emacs-gc-cons-threshold))

(add-hook 'after-init-hook 'after-init)

(setq inhibit-compacting-font-caches t)

;; Resizing the Emacs frame can be costly when changing the font. Disable this
;; to improve startup times with fonts larger than the system default.
(setq frame-resize-pixelwise t)

;; Without this, Emacs will try to resize itself to a specific column size
(setq frame-inhibit-implied-resize nil)

(when (and (not (daemonp)) (not noninteractive))
  ;; Disables unused UI Elements
  (if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
  (if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
  (if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
  (if (fboundp 'tooltip-mode) (tooltip-mode -1))

  ;; A second, case-insensitive pass over `auto-mode-alist' is time wasted.
  ;; No second pass of case-insensitive search over auto-mode-alist.
  (setq auto-mode-case-fold nil)

  ;; Reduce *Message* noise at startup. An empty scratch buffer (or the
  ;; dashboard) is more than enough, and faster to display.
  (setq inhibit-startup-screen t
        inhibit-startup-echo-area-message user-login-name)
  (setq initial-buffer-choice nil
        inhibit-startup-buffer-menu t
        inhibit-x-resources t)

  ;; Disable bidirectional text scanning for a modest performance boost.
  (setq-default bidi-display-reordering 'left-to-right
                bidi-paragraph-direction 'left-to-right)

  ;; Give up some bidirectional functionality for slightly faster re-display.
  (setq bidi-inhibit-bpa t)

  ;; Remove "For information about GNU Emacs..." message at startup
  (advice-add 'display-startup-echo-area-message :override #'ignore)

  ;; Suppress the vanilla startup screen completely. We've disabled it with
  ;; `inhibit-startup-screen', but it would still initialize anyway.
  (advice-add 'display-startup-screen :override #'ignore)

  ;; The initial buffer is created during startup even in non-interactive
  ;; sessions, and its major mode is fully initialized. Modes like `text-mode',
  ;; `org-mode', or even the default `lisp-interaction-mode' load extra packages
  ;; and run hooks, which can slow down startup.
  ;;
  ;; Using `fundamental-mode' for the initial buffer to avoid unnecessary
  ;; startup overhead.
  (setq initial-major-mode 'fundamental-mode
        initial-scratch-message nil)

  ;; Unset command line options irrelevant to the current OS. These options
  ;; are still processed by `command-line-1` but have no effect.
  (unless emacs-debug
    (unless (eq system-type 'darwin)
      (setq command-line-ns-option-alist nil))
    (unless (memq initial-window-system '(x pgtk))
      (setq command-line-x-option-alist nil))))

(setq inhibit-splash-screen t)

(setq package-archives '(("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")
                         ("devel" . "https://elpa.gnu.org/devel/"))
      package-archive-priorities '(("gnu"    . 99)
                                   ("nongnu" . 80)
                                   ("melpa"  . 0)
                                   ("devel" . 100)))
