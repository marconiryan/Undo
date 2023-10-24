module main

import database
import log_undo

fn main() {

	table_using_file := database.parse_file('./meta.json')
	processed_logs := log_undo.process('./file.log')
	aborted_logs := log_undo.aborted_logs(processed_logs)
	undo_logs := log_undo.undo_logs(processed_logs)
	undo_logs_transactions := undo_logs.map(fn (current_log log_undo.LogStructure) string {
		return current_log.transaction_id
	})

	database.display(table_using_file)
	db :=database.setup("./meta.json")
	mut updated := ""
	for undo in undo_logs{
		updated += database.undo(db, table_using_file, undo)
	}

	for transaction in aborted_logs{
		if transaction in undo_logs_transactions{
			println("Transação ${transaction} realizou UNDO (com alterações)")
			continue
		}
		println("Transação ${transaction} realizou UNDO (sem alterações)")

	}
	database.show_table(db, table_using_file)
	println("Valores atualizados:")
	println(updated)
	println("---------------------")
}
