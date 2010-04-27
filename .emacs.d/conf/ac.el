
;;; Require
(require 'auto-complete)
;; Various configurations
(require 'auto-complete-config)
(require 'auto-complete-extension nil t) ;optional
(require 'auto-complete-yasnippet nil t) ;optional
(require 'auto-complete-semantic nil t)  ;optional
(require 'auto-complete-gtags nil t)     ;optional
(require 'auto-complete-octave)

;; Generic setup.
(global-auto-complete-mode t)           ;enable global-mode

(setq ac-auto-start 3)                  ;automatically start
(setq ac-override-local-map nil)        ;don't override local map

(define-key ac-complete-mode-map "\C-n" 'ac-next)
(define-key ac-complete-mode-map "\C-p" 'ac-previous)

;; The mode that automatically startup.
(setq ac-modes
      '(emacs-lisp-mode lisp-interaction-mode lisp-mode scheme-mode
                        c-mode cc-mode c++-mode java-mode jde-mode
                        perl-mode cperl-mode python-mode ruby-mode
                        ecmascript-mode javascript-mode php-mode css-mode
                        makefile-mode sh-mode fortran-mode f90-mode ada-mode
                        xml-mode sgml-mode
                        haskell-mode literate-haskell-mode
                        emms-tag-editor-mode erlang-mode
                        asm-mode
                        org-mode
			go-mode
			latex-mode
			inferior-octave-mode
			octave-mode
			sql-mode
			prolog-mode
			yaml-mode
			message-mode
                        glsl-mode
                        cython-mode
                        mathematica-mode
                        clojure-mode
                        groovy-mode
			))
(add-to-list 'ac-trigger-commands 'org-self-insert-command) ; if you want enable auto-complete at org-mode, uncomment this line

;; The sources for common all mode.
(custom-set-variables
 '(ac-sources
   '(
     ac-source-yasnippet ;this source need file `auto-complete-yasnippet.el'
     ;; ac-source-semantic    ;this source need file `auto-complete-semantic.el'
     ac-source-imenu
     ac-source-abbrev
     ac-source-words-in-buffer
     ac-source-files-in-current-dir
     ac-source-filename
     )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Lisp mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(dolist (hook (list
               'emacs-lisp-mode-hook
               'lisp-interaction-mode
               ))
  (add-hook hook '(lambda ()
                    (add-to-list 'ac-sources 'ac-source-symbols))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; C-common-mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Enables omnicompletion with `c-mode-common'.
(add-hook 'c-mode-common-hook
          '(lambda ()
             (add-to-list 'ac-omni-completion-sources
                          (cons "\\." '(ac-source-semantic)))
             (add-to-list 'ac-omni-completion-sources
                          (cons "->" '(ac-source-semantic)))
             (add-to-list 'ac-sources 'ac-source-gtags)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; C++-mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keywords.
(add-hook 'c++-mode-hook '(lambda ()
                            (add-to-list 'ac-sources 'ac-c++-sources)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Haskell mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keywords.
(add-hook 'haskell-mode-hook '(lambda ()
                                (add-to-list 'ac-sources 'ac-source-haskell)))

