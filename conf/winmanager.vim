
function! <SID>ToggleWindowsManager()
   if IsWinManagerVisible()
      call s:CloseWindowsManager()
   else
      call s:StartWindowsManager()
      exe 'q'
   end
endfunction
