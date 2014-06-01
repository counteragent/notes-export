on buildTitle(originalText)
	set normalizedText to my replace(originalText, ":", "-")
	set finalTitle to my firstChars(normalizedText, 100)
	return finalTitle
end buildTitle

on replace(originalText, fromText, toText)
	set AppleScript's text item delimiters to the fromText
	set the item_list to every text item of originalText
	set AppleScript's text item delimiters to the toText
	set originalText to the item_list as string
	set AppleScript's text item delimiters to ""
	return originalText
end replace

on firstChars(originalText, maxChars)
	if length of originalText is less than maxChars then
		return originalText
	else
		set limitedText to text 1 thru maxChars of originalText
		return limitedText
	end if
end firstChars

on write_to_file(target_file, new_text, append_data)
	try
		set the target_file to the target_file as string
		set the open_target_file to open for access file target_file with write permission
		if append_data is false then set eof of the open_target_file to 0
			write new_text to the open_target_file starting at eof
			close access the open_target_file
		return true
		on error
	try
		close access file target_file
		end try
		return false
	end try
end write_to_file

on remove_markup(this_text)
	set copy_flag to true
	set the clean_text to ""
	repeat with this_char in this_text
		set this_char to the contents of this_char
		if this_char is "<" then
			set the copy_flag to false
		else if this_char is ">" then
			set the copy_flag to true
		else if the copy_flag is true then
			set the clean_text to the clean_text & this_char as string
		end if
	end repeat
	return the clean_text
end remove_markup

tell application "Notes"
	activate
	display dialog "This is the export utility for Notes.app.

" & "Exactly " & (count of notes) & " notes are stored in the application. " & "All notes will will be exported as a simple CSV file stored in a folder of your choice." with title "Notes Export" buttons {"Cancel", "Proceed"} cancel button "Cancel" default button "Proceed"
	set exportFile to (choose file name with prompt "Save As File" default name "My Notes Backup" default location path to desktop) as text
	if exportFile does not end with ".csv" then set exportFile to exportFile & ".csv"

	set counter to 0
	set filename to (exportFile as string)
	set headers to "id, date_created, date_modified, name, body\n"
	set AppleScript's text item delimiters to {return & linefeed, return, linefeed, character id 8233, character id 8232}
	my write_to_file(filename, headers as text, false)

	repeat with each in every note
		set noteID to id of each
		set noteName to name of each
		set noteBody to body of each
		set noteDateCreated to creation date of each
		set noteDateModified to modification date of each
		set noteTitle to my buildTitle(noteName)
		set counter to counter + 1
		set cleanNoteBody to my replace(noteBody, "<br>", "\r")
		set cleanNoteBody to my replace(cleanNoteBody, linefeed, "")
		set cleanNoteBody to my replace(cleanNoteBody, "</p>", "\n")
		set cleanNoteBody to my replace(cleanNoteBody, "<ul class=\"Apple-dash-list\">", "\n")
		set cleanNoteBody to my replace(cleanNoteBody, "<li>", "\t")
		set cleanNoteBody to my replace(cleanNoteBody, "</li>", "\n")
		set cleanNoteBody to my replace(cleanNoteBody, "\"", "\"")
		set cleanNoteBody to my replace(cleanNoteBody, "'", "'")
		set cleanNoteBody to my replace(cleanNoteBody, "’", "'")
		set cleanNoteBody to my replace(cleanNoteBody, "‘", "'")
		set cleanNoteBody to my replace(cleanNoteBody, "“", "\"")
		set cleanNoteBody to my replace(cleanNoteBody, "”", "\"")

		set cleanNoteBody to do shell script "/bin/echo -n " & quoted form of cleanNoteBody & " | sed -e 's/\"/'\\''/g'"
		set fullNoteRecord to counter & "," & noteDateCreated & "," & noteDateModified & "," & noteName & "," & "\"" & my remove_markup(cleanNoteBody) & "\"\n"
		my write_to_file(filename, fullNoteRecord as text, true)
	end repeat

	display alert "Notes Export" message "All notes were exported successfully." as informational
end tell
