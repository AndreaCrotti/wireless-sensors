(add-to-list 'load-path "$HOME/.emacs.d/site-lisp")
(add-to-list 'load-path "$HOME/.emacs.d/conf")
(add-to-list 'load-path "$HOME/.emacs.d/yasnippet")
(add-to-list 'load-path "$HOME/.emacs.d/auto-complete")

(load-file "$HOME/.emacs.d/conf/yasnippet.el")
(load-file "$HOME/.emacs.d/conf/ac.el")

;; Nesc mode
(add-to-list 'auto-mode-alist '("\\.nc$" . nesc-mode ))

(autoload 'nesc-mode "nesc" nil t)

;; enabling winner mode for window reconfiguration
(winner-mode 1)

(windmove-default-keybindings 'shift) ; very nice, moving with a shift between buffers
(setq require-traling-newline t) ; always new line at end

(mouse-avoidance-mode 'animate) ;; move away the mouse from the cursor

(size-indication-mode) ;; show approximate size

(global-set-key "\C-x\C-b" 'ibuffer) ;; manage buffers with ibuffer

(require 'color-theme)
(eval-after-load "color-theme"
  '(progn
     (color-theme-initialize)))

;; gain more pixels, more useful on the netbook, checking before if we are on X11 or console
;; (menu-bar-mode)
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))

(display-time-mode 1)
(transient-mark-mode 1)
(setq inhibit-startup-message t)
;;show nothing in *scratch* when started
(setq initial-scratch-message nil)

;; Some useful stuff
(show-paren-mode t)
(column-number-mode t)
;; always truncate lines (useful for netbook), not working yet in ORG MODE
(setq truncate-lines nil)
;; Setting indent-tabs-mode for only spaces
(setq-default indent-tabs-mode nil)

(require 'ido)
(ido-mode t)

;; for changelogs
(setq add-log-always-start-new-record 1)
(add-hook 'before-save-hook 'time-stamp)
(setq time-stamp-format "%02d-%02m-%:y, %02H:%02M")

                                        ; VCS stuff
(require 'magit)
                                        ; remember positions
(require 'saveplace)
(require 'eldoc)

;; Setting some font alternatives
(setq face-font-family-alternatives (quote (("courier" "fixed" "terminus") ("helv" "helvetica" "arial" "fixed"))))

;; Reenabling two disabled commands
(put 'upcase-region 'disabled nil)

(put 'downcase-region 'disabled nil)

                                        ; Setting the magit status key, git must be also in the path
(global-set-key "\C-xg" 'magit-status)

(global-set-key "\C-c\C-d" 'duplicate-line)

                                        ; using iswitch buffer
(iswitchb-mode 1)

;; Using uniquify for better handling of buffers with same name
(require 'uniquify)
;; Using part of the directory in this case
(setq uniquify-buffer-name-style 'forward)

(defconst default-closing-char ";"
  "default closing char, change in newline-force-close-alist if needed")

(setq newline-force-close-alist
      '((python-mode . ":")))

(global-set-key (kbd "M-RET") 'newline-force)
(global-set-key [M-S-return] 'newline-force-close)

;; My own functions
(defun newline-force()
  "Goes to newline leaving untouched the rest of the line"
  (interactive)
  (progn
    (end-of-line)
    (newline-and-indent)))

(defun newline-force-close()
  (interactive)
  (end-of-line)
  (let ((closing-way (assoc major-mode newline-force-close-alist))
        closing-char)
    ;; Setting the user defined or the constant if not found
    (if (not closing-way)
	(progn
	  (message "closing char not defined for this mode, using default")
	  (setq closing-char default-closing-char))
      (setq closing-char (cdr closing-way)))
    (when (not (bobp))
      ;; if we're at beginning of buffer, the backward-char will beep
      ;; :( This works even in the case of narrowing (e.g. we don't
      ;; look outside of the narrowed area.
      (when (not (looking-at closing-char))
 	(insert closing-char))
      (newline-force))))
