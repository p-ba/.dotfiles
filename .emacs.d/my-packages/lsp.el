;;; lsp.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-

(defun my/eglot-setup-completion ()
  "Prefer Eglot completions in managed buffers, with Cape as fallback."
  (setq-local completion-at-point-functions
              (list #'my/eglot-completion-at-point
                    #'cape-file
                    #'my/cape-dabbrev-dict-keyword)))

(defun my/eglot-completion-at-point ()
  "Return Eglot completion data only when a live server is available."
  (when (and (bound-and-true-p eglot--managed-mode)
             (ignore-errors (eglot-current-server)))
    (ignore-errors (eglot-completion-at-point))))

(setq vue-ts-options #s(hash-table test equal data
                                   ("plugins"
                                    [#s(hash-table test equal data
                                                   ("name" "@vue/typescript-plugin"
                                                    "location" ""
                                                    "languages" ["vue"]))])))

(use-package eglot
  :defer t
  :hook ((eglot-managed-mode . my/eglot-setup-completion))
  :bind (("C-c a" . eglot-code-actions))
  :custom
  (eglot-connect-hook nil)
  (eglot-stay-out-of '(flymake))
  (eglot-ignored-server-capabilities '(:documentHighlightProvider :inlayHintProvider :insertReplaceSupport))
  :config
  (add-to-list 'eglot-server-programs `(vue-mode . ("typescript-language-server" "--stdio" :initializationOptions ,vue-ts-options)))
  (add-to-list 'eglot-server-programs '(swift-mode . ("xcrun" "sourcekit-lsp")))
  (add-to-list 'eglot-server-programs '(php-mode "intelephense" "--stdio"))
  (add-to-list 'eglot-server-programs '(php-ts-mode "intelephense" "--stdio"))
  (add-to-list 'eglot-server-programs '(typescript-mode "typescript-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs '(typescript-ts-mode "typescript-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs '(js-mode "typescript-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs '(js-ts-mode "typescript-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs '(tsx-mode "typescript-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs '(tsx-ts-mode "typescript-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs '(jsx-mode "typescript-language-server" "--stdio"))
  (add-to-list 'eglot-server-programs '(go-ts-mode "gopls" "serve")))

(add-to-list 'load-path (concat user-emacs-directory "site-lisp/eglot-booster/"))
(use-package eglot-booster
  :after eglot
  :ensure nil
  :config (eglot-booster-mode))

;; (use-package flycheck-eglot
;;   :ensure t
;;   :after (flycheck eglot)
;;   :config
;;   (global-flycheck-eglot-mode 1))

(provide 'lsp)
