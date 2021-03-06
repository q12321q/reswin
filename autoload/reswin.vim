""" Reswin autoload file

"""""""""""""""""""""""""""""""""
""" Public functions
"""""""""""""""""""""""""""""""""

""" Print a string into the reswin
function g:reswin#Print(str, ...)
  if exists('a:1')
    let l:options = a:1
  else
    let l:options = {}
  endif

  let callback = copy(a:)
  function callback.call()
    call s:printer(self.str)
  endfunction
  call s:execute_in_window(callback, l:options)
endfunction

""" Print the result of a shell command into the reswin
function! g:reswin#Shell(command, ...) range
  if exists('a:1')
    let l:options = a:1
  else
    let l:options = {}
  endif
  let callback = copy(a:)
  let callback.selection = getline(a:firstline, a:lastline)
  function callback.call()
    call setline(1, self.selection)
    silent execute ":%!" . self.command
  endfunction
  call s:execute_in_window(callback, l:options)
endfunction

""" Print the result of the evalution of a expresion into the reswin
function g:reswin#Eval(expression, ...)
  if exists('a:1')
    let l:options = a:1
  else
    let l:options = {}
  endif
  let callback = copy(a:)
  function callback.call()
    call s:printer(eval(self.expression))
  endfunction
  call s:execute_in_window(callback, l:options)
endfunction

""" Print the result of the execution of a command into the reswin
function g:reswin#Command(command, ...)
  if exists('a:1')
    let l:options = a:1
  else
    let l:options = {}
  endif
  let callback = copy(a:)
  function callback.call()
    redir @z
    execute 'silent '.self.command
    redir END
    call s:printer(@z)
  endfunction
  call s:execute_in_window(callback, l:options)
endfunction

"""""""""""""""""""""""""""""""""
""" Private functions
"""""""""""""""""""""""""""""""""

""" Create a new buffer
function! s:create_buffer(parent, name, options)
  let l:buffer = bufnr(a:name, 1)

  call s:focus_buffer(l:buffer, a:options)

  " Set some defaults.
  call setbufvar(l:buffer, "&swapfile", 0)
  call setbufvar(l:buffer, "&buftype", "nofile")
  " call setbufvar(l:buffer, "&bufhidden", "wipe")
  call setbufvar(l:buffer, "vimpipe_parent", a:parent)

  if has_key(a:options, 'onCreate')
    call a:options.onCreate(l:buffer)
  endif

  return l:buffer
endfunction

""" Focus to a buffer
""" param {Number} bufferNr number of the buffer to focus on
function! s:focus_buffer(bufferNr, options)
  let switchbuf_before = &switchbuf
  set switchbuf=useopen

  " Split & open.
  if !has_key(a:options, 'position')
    let l:position = ''
  elseif a:options.position == 'right'
    let l:position = 'vertical belowright'
  elseif a:options.position == 'left'
    let l:position = 'vertical topleft'
  elseif a:options.position == 'top'
    let l:position = 'topleft'
  else
    let l:position = 'belowright'
  endif

  silent execute l:position . ' sbuffer ' . a:bufferNr

  let &switchbuf = switchbuf_before
endfunction

""" Create or focus to a buffer
function! s:create_or_focus_buffer(parent, name, options)
  let l:buffer = bufnr(a:name)
  if l:buffer == -1
    let l:buffer = s:create_buffer(a:parent, a:name, a:options)
  else
    call s:focus_buffer(l:buffer, a:options)
  endif

  return l:buffer
endfunction

""" Execute a function in the context of a reswin
function! s:execute_in_window(pipeFunction, ...)
  if exists('a:1')
    let l:options = a:1
  else
    let l:options = {}
  endif
  if has_key(l:options, 'title')
    let l:title = ' ' . l:options.title
  else
    let l:title = ' generic'
  endif
  let l:parent = bufnr("%")
  let l:buffer = s:create_or_focus_buffer(l:parent, "[ResWin]".l:title, l:options)

  if has_key(l:options, 'preservePosition') && l:options.preservePosition
    let l:cursor_position = getpos('.')
  endif

  if has_key(l:options, 'filetype')
    call setbufvar(l:buffer, "&filetype", l:options.filetype)
  endif

  if has_key(l:options, 'width')
    execute 'vertical resize ' . l:options.width
  endif

  if has_key(l:options, 'height')
    execute 'resize ' . l:options.height
  endif

  if has_key(l:options, 'onOpen')
    call l:options.onOpen(l:buffer)
  endif

  " Clear the buffer.
  redraw

  if !has_key(l:options, 'clear') || l:options.clear
    execute ":%d _"
  endif

  call a:pipeFunction.call()

  if has_key(l:options, 'onComplete')
    call l:options.onComplete(l:buffer)
  endif

  if has_key(l:options, 'preservePosition') && l:options.preservePosition
     call setpos('.', l:cursor_position)
  endif

  if !has_key(l:options, 'keepFocus') || l:options.keepFocus
    call s:focus_buffer(l:parent, l:options)
  endif
endfunction

""" Print a string in the current buffer
function! s:printer(str)
  let saved_z_register = @z
  let @z = a:str
  normal "zp
  let @z = saved_z_register
  silent redraw
endfunction

" vim: set foldlevel=1 foldmethod=marker:
