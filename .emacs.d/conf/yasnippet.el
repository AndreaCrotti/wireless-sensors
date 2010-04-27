(require 'yasnippet)

(setq yas/root-directory
      '("~/.emacs.d/my-snippets/text-mode/"
        "~/.emacs.d/yasnippet/"))

;; Maybe needed to set to fixed for some modes
(setq yas/indent-line 'auto)

(yas/initialize)

(setq yas/ignore-filenames-as-triggers nil)

(mapc 'yas/load-directory yas/root-directory)

;; don't make backups in the snippet folder, they mess up yasnippet
;; Should this really go here?
(add-to-list 'backup-directory-alist '("/my-snippets/" . "/tmp/"))

