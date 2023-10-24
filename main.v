module main

import database
import log

fn main() {

	// ToDo Selects, log module name, tests and optimize
	table_using_file := database.parse_file('./meta.json')
	processed_logs := log.process('./file.log')
	aborted_logs := log.aborted_logs(processed_logs)
	undo_logs := log.undo_logs(processed_logs)

	for transaction in aborted_logs{
		println("Transação ${transaction} realizou UNDO")
	}

	db :=database.setup("./meta.json")
	for undo in undo_logs{
		database.undo(db, table_using_file, undo)
	}
}
