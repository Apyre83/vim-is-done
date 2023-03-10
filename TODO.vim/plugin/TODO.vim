"**************************************************************************** "
"                                                                              "
"                                                         :::      ::::::::    "
"    TODO.vim                                           :+:      :+:    :+:    "
"                                                     +:+ +:+         +:+      "
"    By: lfresnay <lfresnay@student.42.fr>          +#+  +:+       +#+         "
"                                                 +#+#+#+#+#+   +#+            "
"    Created: 2023/03/07 14:41:12 by lfresnay          #+#    #+#              "
"    Updated: 2023/03/10 22:47:34 by lfresnay         ###   ########.fr        "
"                                                                              "
" **************************************************************************** "


function! LoadCookies()
	

	let l:lines = readfile(g:savedPATH)
	let g:cookies = l:lines[0]

	" if airline plugin is active
	if match(&runtimepath, 'airline') != -1
		let g:airline_section_z = 'cookies: %{g:cookies}'
	else
		" Do something
	endif

endfunction


function! SaveCookies()

	" writefile works this way: writefile(List, Glob, Option[char])

	call writefile(split(g:cookies, '\n', 1), glob(g:savedPATH))

endfunction


"
" Function to call in the vimrc file.
"
function! InitTODO()

	" Open a new window for the todo list, to the left
	vertical new

	" I think 31 was a good value, feel free to change it
	" Not that the todo text won't be centered = todo ?
	vertical resize 31

	" Store the todo window in a global variable
	let g:windowTODO = winnr()

	" Store the PATH of the data file
	let g:dataPATH = $HOME . "/.vim/plugged/TODO.vim/data/data"

	" Store the PATH of the saved (cookies) file
	let g:savedPATH = $HOME . "/.vim/plugged/TODO.vim/data/saved"

	" Open the todo list file on the window
	" Note that we have to use view and then override with w!, because open
	" Actually creates a new directory
	execute ":view $HOME/.vim/plugged/TODO.vim/data/data"
	execute ":w!"

	" Load the cookies which are only displayed with the plugin airline
	" They are still accessibles with the variable g:cookies
	call LoadCookies()

	" Call this loadCookies function on leaving
	autocmd VimLeave * call SaveCookies()

	" Go back to main screen
	wincmd p

endfunction


" This function let you add a new todo to your todo list
function! AddTODO()
	
	let l:prompt = input("What are your ambitions: ")

	" We don't want to add nothing
	if (prompt == "")
		return
	endif

	" Goto to todo window
	execute g:windowTODO . "wincmd w"

	" We calculate the position of the new todo
	let l:number = 1
	while (CheckIfExists(l:number) == 1)
		let l:number += 1
	endwhile

	" We add the new todo to the todo list
	call AppendTODO(l:prompt, l:number)

	" We save
	execute ":w!"

	" Go back to main screen
	wincmd p

endfunction


" This function consists in playing an 'animation'
"
" For each character, we save it, put a random one, wait for few miliseconds,
" and replace with the old one
"
" This is just a simple animation, it doesn't have any effect on the todo list
" It is called when you complete a todo
"
function! PlayAnimation()

	" If there is no file to save (since we wanna readfile the current file)
	if @% == ""
		return
	endif

	" We save the current file and go to the beginning of the text
	execute ":w!"
	execute ":1"

	" These are all the characters to display (random ones)
	" It was annoying to add some special characters since they need a '\'
	let l:characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

	" Reading all the file
	let l:lines = readfile(@%)
	
	" We want to save the one we are replacing, that are temporary, feel free
	" to change the arraysize
	let l:olds = []
	let l:arraysize = 60
	for i in range(l:arraysize)
		call add(l:olds, -1)
	endfor

	for l:line in l:lines

		" count is the number of the character in the line that we are replacing
		let l:count = 0

		for l:char in l:line

			" If it's time to replace the new one by the old one
			" I'm using the model s/\%{lineNo}c./old_char/ to replace whatever
			" character is at position lineNo by the old_char
			" https://stackoverflow.com/questions/33566593/command-for-replace-nth-symbol-in-vim
			if (l:count > (l:arraysize - 1) )
				execute ":s/\\\%" . (l:count - (l:arraysize - 1)) . "c./" . l:olds[l:count % l:arraysize] . "/"
			endif

			" not ready yet, to change the color of the character
			" exe 'match ErrorMsg /\%' . l:count  . 'v\%' . line(".") . 'l./'

			" We store the old character in the array
			let l:olds[l:count % l:arraysize] = l:char

			" We have espace the '/' and '\' characters here
			if (l:olds[l:count % l:arraysize] == "\\")
				let l:olds[l:count % l:arraysize] = "\\\\"
			elseif (l:olds[l:count % l:arraysize] == "/")
				let l:olds[l:count % l:arraysize] = "\\/"
			endif

			" We get a random char
			let l:seed = l:characters[srand()[0] % len(l:characters)]
			" And we put it at the position l:count + 1 because it starts with
			" 1 (worst thing possible)
			execute ":s/\\\%" . (l:count + 1) . "c./" . l:seed . "/"

			" We wait for a few miliseconds, i'm not sure if you we have to
			" redraw with this little time but just in case
			redraw
			sleep 7m

			" go to the next char
			let l:count += 1

		endfor

		" This big while loop is whenever the line is finished but we haven't
		" replaced the new characters at the very end of it (that are still in
		" the old array)
		"
		" There are 2 cases:
		" 	- If the line is smaller than the buffer
		"
		" 	And if not
		"
		" The only thing that differs between the two cases is the column you
		" want to put the characters in
		"
		let l:i = 0
		while (l:i < l:arraysize 6h l:i < len(l:line))
		
			if (l:arraysize > len(l:line))
				" Since it's in an order, if we find a -1, everything after is
				" a -1 aswell
				if (l:olds[l:i] == -1)
					break
				endif
				" We again replace the new character placed before by the old
				" one (that makes sense)
				execute ":s/\\\%" . (l:i + 1) . "c./" . l:olds[l:i] . "/"
			else
				if (l:olds[l:count % l:arraysize] == -1)
					break
				endif
				execute ":s/\\\%" . (l:count - (l:arraysize - 1)) . "c./" . l:olds[l:count % l:arraysize] . "/"
			endif

			" We replace the data by a -1 and increment the rest
			let l:olds[l:count % l:arraysize] = -1
			let l:i += 1
			let l:count += 1

		endwhile

		" We go to the next line
		execute ":+1"

	endfor

endfunction


" This function is called when you call AddTODO()
function! AppendTODO(prompt, number)

	" We read the file data because i don't like dealing with buffers
	let l:lines = readfile(g:dataPATH)

	" This represente the number of the line it should be added to
	let l:nbLigne = 1

	" If there is no todo, because of the format i want, i can just go to line 3
	if (a:number == 1)
		let l:nbLigne = 3
	else
		" We loop through the lines of the file until the next one is number - 1
		for l:line in l:lines

			if (str2nr(l:line) == (a:number - 1))
				break
			elseif (l:line == "	   LATEST DID:")
				let l:nbLigne -= 1
				break
			endif
			let l:nbLigne += 1

		endfor
	endif


	execute ":" . l:nbLigne

	call InsertVarSpace(a:number . ". [ ] " . a:prompt . "\n\n", 0)

endfunction


" This function is called to complete a todo
" It checks if the todo exists, if it does, it adds it to the todo list,
" then it moves all the indexes of the todos
"
function! Complete(id)
	

	if (CheckIfExists(a:id) == 0)
		return
	endif
	
	execute g:windowTODO . "wincmd w"

	execute ":0"
	call MoveNegatives()

	execute ":0"
	call MoveTODO(a:id)

	execute ":0"
	call MovePositives(a:id)

	execute ":w"

	let g:cookies += 1

	" Go back to main screen
	wincmd p

	call PlayAnimation()


endfunction

" This function just moves the positives indexes of the todos at n - 1
function! MovePositives(id)

	let l:lines = readfile(g:dataPATH)

	for l:line in l:lines

		if (str2nr(l:line) > a:id)
			" We can easily replace the line using substitute
			execute ":s/" . str2nr(l:line) . "/" . (str2nr(l:line) - 1) . "/g"
		endif

		execute ":+1"

	endfor

endfunction

" Same as for negativee
function! MoveNegatives()
	
	let l:lines = readfile(g:dataPATH)

	" If line starts with '-' then decrement 1
	for l:line in l:lines

		if (l:line[0] == '-')
			execute ":s/" . str2nr(l:line) . "/" . (str2nr(l:line) - 1) . "/g"
		endif
		execute ":+1"

	endfor

endfunction

" This function move the complete todo into the completed todos list, below
" the LATEST DID:
function! MoveTODO(id)

	let l:lines = readfile(g:dataPATH)

	" Look for the line to delete and delete it
	for l:line in l:lines

		" Here if we find the line to delete, we do a delete 2 because
		" we also want to delete the empty line
		if (l:line[0] == a:id)
			execute ":delete 2"
			break
		endif

		execute ":+1"
	endfor

	execute ":w"
	" We get the position of the LATEST DID: since we are going to put it below
	" it
	let l:latestPos = GetLatestPos()

	execute ":" . (l:latestPos + 1)
	call AddEmptyLineBelow()

	" Since this is the latest did, it will always starts with -1. [x], easy
	call InsertVar("-1. [x]" . GetLastChar(l:line, 6))
	execute ":w"

endfunction

" This function checks if the index of the todo exists
" it returns 1 if it does, 0 if it doesn't
function! CheckIfExists(id)

	if (str2nr(a:id) <= 0)
		return 0
	endif

	let l:lines = readfile(g:dataPATH)
	for l:line in l:lines

		if (str2nr(l:line == a:id))
			return 1
		endif

	endfor
	return 0

endfunction

" This is used to get the position of the 'LATEST DID:'
function! GetLatestPos()
	let l:lines = readfile(g:dataPATH)
	let l:numberLine = 1

	for l:line in l:lines
		if (l:line == "	   LATEST DID:")
			return l:numberLine
		endif
		let l:numberLine += 1
	endfor
	return 0
endfunction

" Can get the last nth element
"
" GetLastChar("test", 1) -> "est"
"
" At first i didn't know i could just do string[3:] but it's always cool to
" recreate some useful function :)
"
function! GetLastChar(string, value)
	let l:count = 0
	let l:result = ""
	for l:char in a:string
		if l:count >= a:value
			let l:result .= a:string[l:count]
		endif
		let l:count += 1
	endfor
	return (l:result)
endfunction


" This function is called when i want to insert text, and chose to add a new
" line below it or not
function! InsertVarSpace(var, addLine)
	execute ":normal! i" . a:var
	if (a:addLine == 1)
		call AddEmptyLineBelow()
	endif
endfunction
