module log

import os
import regex

[flag]
enum LogStatus {
	unprocessed
	processed
	aborted
	ignored
}

[flag]
enum LogLabel {
	start_transaction
	commit
	start_checkpoint
	end_checkpoint
	change
}

const (
	start_transaction = 'start'
	commit = 'commit'
	start_checkpoint = 'startckpt'
	end_checkpoint = 'endckpt'
)

struct LogStructure {
mut:
	transaction_id string
	values         []string
	label          LogLabel
	status         LogStatus
}

pub fn parse(path string) {
	file_content := os.read_file(path) or { return }
	mut regex_find_log := regex.regex_opt('<[^>]*>') or { return }
	find_all_str := regex_find_log.find_all_str(file_content)
	for all_str in find_all_str {
		parsed := all_str.trim('<').trim('>').replace(' ', '').split(',')
		classified := classify(parsed)
		println(parsed)
		println(classified)

	}
}

pub fn classify(parsed_log []string) LogStructure {
	is_special_label := parsed_log.len == 1
	mut log := LogStructure{
		status: .unprocessed
	}
	if !is_special_label {
		log.label = LogLabel.change
		log.transaction_id = parsed_log[0].to_lower()
		log.values = parsed_log[1..parsed_log.len]
		return log
	}

	special_label := parsed_log[0].to_lower()
	mut find_transaction_id_regex := regex.regex_opt(r'[A-Za-z]\d') or { return LogStructure{status: .ignored} }
	transaction_id_match := find_transaction_id_regex.find_all_str(special_label)
	mut transaction_id := ''

	if transaction_id_match.len > 0 {
		transaction_id = transaction_id_match.first()
	}

	last_index_commit := special_label.last_index(commit)
	is_commit := last_index_commit != none && special_label.len - last_index_commit >= 3
	if is_commit && transaction_id.len > 0 {
		log.transaction_id = transaction_id
		return log
	}

	last_index_start_transaction := special_label.last_index(start_transaction)
	is_start_transaction := last_index_start_transaction != none && special_label.len - last_index_start_transaction >= 3

	if is_start_transaction && transaction_id.len > 0 {
		log.transaction_id = transaction_id
		log.label = LogLabel.start_transaction
		return log
	}
	last_index_start_checkpoint := special_label.last_index(start_checkpoint)
	is_start_checkpoint := last_index_start_checkpoint != none && special_label.len - last_index_start_checkpoint >= 3
	if is_start_checkpoint && transaction_id.len > 0{
		log.transaction_id = transaction_id
		log.label = LogLabel.start_checkpoint
		return log
	}
	is_end_checkpoint := special_label.last_index(end_checkpoint)
	if is_end_checkpoint != none {
		log.transaction_id = transaction_id
		log.label = LogLabel.end_checkpoint
		return log
	}
	return LogStructure{status: .ignored}
}
