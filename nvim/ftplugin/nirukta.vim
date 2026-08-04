" ftplugin/nirukta.vim  — buffer-local settings for nirukta files

let s:fmt = expand('~/Software/nirukta/format.py')
" only wire up the formatter if the nirukta repo's format.py is present
if filereadable(s:fmt)
  let &l:formatprg = 'uv run ' . s:fmt . ' 2>/dev/null'
endif

setlocal expandtab
setlocal textwidth=0
setlocal formatoptions=

" Vedic swara marks \' and \_ inside words; the tree-sitter grammar lexes
" whole words, so highlight these with a window match over the extmarks
if !exists('w:nirukta_swara_match')
  let w:nirukta_swara_match = matchadd('slokaSwara', '\\[_'']', 200)
endif
