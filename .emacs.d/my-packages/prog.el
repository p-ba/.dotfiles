;;; prog.el --- DESCRIPTION -*- no-byte-compile: t; lexical-binding: t; -*-

(use-package dumb-jump
  ;; Register after xref: hook must not run before dumb-jump (or its autoloads) exists.
  :after xref
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
  (setq dumb-jump-force-searcher 'rg))

(use-package web-mode
  ;; Not deferred: `vue-mode' / `php-mode' are defined here and must register in `auto-mode-alist' at load time.
  :config
  (define-derived-mode vue-mode web-mode "Vue")
  (define-derived-mode php-mode web-mode "PHP")
  (add-to-list 'auto-mode-alist '("\\.vue\\'" . vue-mode))
  (add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode)))

;; (use-package php-ts-mode
;;   :mode (("\\.php$" . php-ts-mode)))

(use-package go-ts-mode
  :defer t
  :mode "\\.go\\'")

(use-package yaml-ts-mode
  :defer t
  :mode "\\.ya?ml\\'")

(use-package typescript-ts-mode
  :defer t)

(use-package swift-mode
  :mode "\\.swift\\'")

(use-package editorconfig
  :defer t)

(use-package markdown-mode
  :defer t
  :mode (("\\.md$" . gfm-mode))
  :commands gfm-mode
  :custom (markdown-command "pandoc --standalone --mathjax --from=markdown"))

(use-package yasnippet
  :defer t
  :config
  (yas-reload-all))

(use-package highlight-indent-guides
  :defer t
  :hook ((yaml-ts-mode . highlight-indent-guides-mode)))

(defun my/prog-mode-extras ()
  "Enable non-essential programming extras after the buffer is displayed."
  (let ((buffer (current-buffer)))
    (run-with-idle-timer
     0.05 nil
     (lambda ()
       (when (buffer-live-p buffer)
         (with-current-buffer buffer
           (when (derived-mode-p 'prog-mode)
             (editorconfig-mode 1)
             (yas-minor-mode 1)
             (display-fill-column-indicator-mode 1))))))))

(add-hook 'prog-mode-hook #'my/prog-mode-extras)

(provide 'prog)
