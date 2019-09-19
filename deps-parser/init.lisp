(defun load-system ()
  (pushnew :mcclim-ffi-freetype *features*)
  (ql:quickload "infoparser"))
