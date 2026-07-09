;;; autocomplete.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-

(use-package dabbrev
  :config
  ;; Swap M-/ and C-M-/
  (global-set-key (kbd "M-/") 'dabbrev-completion)
  (global-set-key (kbd "C-M-/") 'dabbrev-expand)
  (global-set-key [remap dabbrev-expand] 'hippie-expand)
  (setq dabbrev-case-fold-search nil
		dabbrev-case-replace nil)
  (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")
  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'pdf-view-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'tags-table-mode))

;; (use-package icomplete
;;   :bind (:map icomplete-minibuffer-map
;;               ("C-n" . icomplete-forward-completions)
;;               ("C-p" . icomplete-backward-completions)
;;               ("C-v" . icomplete-vertical-toggle)
;;               ("RET" . icomplete-force-complete-and-exit))
;;   :hook
;;   (after-init-hook . (lambda ()
;;                        (fido-mode -1)
;;                        (icomplete-vertical-mode 1)))
;;   :config
;;   (setq icomplete-delay-completions-threshold 0)
;;   (setq icomplete-compute-delay 0)
;;   (setq icomplete-show-matches-on-no-input t)
;;   (setq icomplete-hide-common-prefix nil)
;;   (setq icomplete-prospects-height 10)
;;   (setq icomplete-separator " . ")
;;   (setq icomplete-with-completion-tables t)
;;   ;;(setq icomplete-in-buffer t)
;;   (setq icomplete-max-delay-chars 0)
;;   (setq icomplete-scroll t)
;;   (icomplete-mode t)
;;   (icomplete-vertical-mode t))

;; Vertico/Corfu use `set-local' from GNU ELPA `compat'; the built-in
;; Emacs `compat.el' stub does not define it.
(use-package compat
  :demand t)

(use-package vertico
  :init
  (vertico-mode)
  :custom
  (vertico-cycle t)
  (vertico-resize t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  ;; Keep `orderless' as the default style, but make *file name completion*
  ;; use a fast fuzzy scorer via `fussy' + `fzf-native'.
  (completion-category-overrides '((file (styles fussy partial-completion basic)))))

;; Native fzf scoring backend used by `fussy'.
;; This package is not on MELPA, so we install it via `package-vc' when needed.
(use-package fzf-native
  :ensure nil
  :init
  (require 'package)
  (when (and (fboundp 'package-vc-install)
             (not (package-installed-p 'fzf-native)))
    (package-vc-install "https://github.com/dangduc/fzf-native"))
  :config
  (when (fboundp 'fzf-native-load-dyn)
    (fzf-native-load-dyn)))

(use-package fussy
  :after (fzf-native)
  :config
  (setq fussy-score-ALL-fn 'fussy-fzf-score)
  (setq fussy-filter-fn 'fussy-filter-default)
  (setq fussy-use-cache t)
  (setq fussy-compare-same-score-fn 'fussy-histlen->strlen<)
  (fussy-setup)
  ;; Corfu can reuse cached results; wipe cache on new completion sessions.
  (with-eval-after-load 'corfu
    (advice-add 'corfu--capf-wrapper :before #'fussy-wipe-cache)))

(use-package cape
  :init
  (defun my/cape-dabbrev-dict-keyword ()
    (cape-wrap-super #'cape-dabbrev #'cape-keyword #'cape-dict))
  (add-hook 'completion-at-point-functions #'my/cape-dabbrev-dict-keyword)
  (add-hook 'completion-at-point-functions #'cape-file))

(use-package corfu
  :custom
  ;; always have the same width
  (corfu-min-width 80)
  (corfu-max-width corfu-min-width)
  (corfu-scroll-margin 4)
  ;; have corfu wrap around when going up
  (corfu-cycle t)
  (corfu-preselect-first t)
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 2)
  :config
  ;; Popupinfo vars/modes live in `corfu-popupinfo' — enable after core Corfu loads.
  (setq corfu-popupinfo-delay '(0.5 . 0.5))
  (require 'corfu-popupinfo)
  (global-corfu-mode 1)
  (corfu-history-mode 1)
  (corfu-popupinfo-mode 1))

(use-package emacs
  :custom
  (text-mode-ispell-word-completion nil))

(use-package marginalia
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode))

(provide 'autocomplete)
