module log_undo

import os
import regex

[flag]
enum LogStatus {
	unprocessed
	processed
	aborted
	ignored
	undo
	done
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

pub struct LogStructure {
pub mut:
	transaction_id string
	values         []string
	label          LogLabel
	status         LogStatus
}

pub fn undo_logs(invalid_logs []LogStructure) []LogStructure{
	return invalid_logs.filter(fn (log LogStructure) bool {
		return log.status == LogStatus.undo
	})
}

pub fn aborted_logs(invalid_logs []LogStructure) []string{
	return invalid_logs
	.filter(fn (log LogStructure) bool {
		return log.status == LogStatus.aborted
	})
	.map(fn (log LogStructure) string {
		return log.transaction_id
	})
}

pub fn process(path string) []LogStructure{
	mut logs := parse_and_classify(path)

	for log_index in 0..logs.len {
		log := logs[log_index]
		if log.status == LogStatus.processed {
			continue;
		}
		has_more_logs := log_index + 1 <= logs.len
		if log.label == LogLabel.commit && has_more_logs{
			for find_components_transaction in  log_index..logs.len{
				is_same_transaction := log.transaction_id == logs[find_components_transaction].transaction_id
				is_start_transaction := logs[find_components_transaction].label == LogLabel.start_transaction
				if is_same_transaction {
					logs[find_components_transaction].status = LogStatus.processed
				}

				if is_same_transaction &&  is_start_transaction{
					break
				}
			}
		}

		if log.label == LogLabel.end_checkpoint && has_more_logs {
			logs[log_index].status = LogStatus.processed
			for find_components_transaction in  log_index..logs.len{
				is_same_transaction := log.transaction_id == logs[find_components_transaction].transaction_id
				is_start_checkpoint := logs[find_components_transaction].label == LogLabel.start_checkpoint
				if is_same_transaction &&  is_start_checkpoint {
					println("\nINFO: Checkpoint encontrado entre ${logs.len - find_components_transaction} - ${logs.len - log_index}\n")
					logs = logs[..find_components_transaction]
					break
				}
			}
		}
	}

	unprocessed_logs := logs.filter(fn (it LogStructure) bool {
		return it.status == LogStatus.unprocessed
	})

	invalid_logs := unprocessed_logs.map(fn (log LogStructure) LogStructure {
		mut new_log := log

		if log.label == LogLabel.change {
			new_log.status = LogStatus.undo
			return new_log
		}

		if log.label == LogLabel.start_transaction{
			new_log.status = LogStatus.aborted
			return new_log
		}

		new_log.status = LogStatus.ignored
		return new_log
	})

	return invalid_logs
}

pub fn parse_and_classify(path string) [] LogStructure {
	file_content := os.read_file(path) or { return []LogStructure{} }
	mut regex_find_log := regex.regex_opt('<[^>]*>') or {
		panic(err)
	}
	find_all_str := regex_find_log.find_all_str(file_content)
	mut classified_log := []LogStructure{}
	for all_str in find_all_str {
		parsed := all_str.trim('<').trim('>').replace(' ', '').split(',')
		classified := classify(parsed)
		classified_log << classified;

	}
	return classified_log.reverse()
}

pub fn classify(parsed_log []string) LogStructure {
	special_label := parsed_log[0].to_lower()
	is_special_label := parsed_log.len == 1
	last_index_start_checkpoint := special_label.last_index(start_checkpoint)
	mut log := LogStructure{
		status: .unprocessed
	}
	if !is_special_label && last_index_start_checkpoint == none{
		log.label = LogLabel.change
		log.transaction_id = parsed_log[0].to_lower()
		log.values = parsed_log[1..parsed_log.len]
		return log
	}

	mut find_transaction_id_regex := regex.regex_opt(r'[A-Za-z]\d') or {
		panic(err)
	}
	transaction_id_match := find_transaction_id_regex.find_all_str(special_label)
	mut transaction_id := ''

	if transaction_id_match.len > 0 {
		transaction_id = transaction_id_match.first()
	}

	last_index_commit := special_label.last_index(commit)
	is_commit := last_index_commit != none && special_label.len - last_index_commit >= 3
	if is_commit && transaction_id.len > 0 {
		log.transaction_id = transaction_id
		log.label = LogLabel.commit
		return log
	}

	last_index_start_transaction := special_label.last_index(start_transaction)
	is_start_transaction := last_index_start_transaction != none && special_label.len - last_index_start_transaction >= 3


	is_start_checkpoint := last_index_start_checkpoint != none && special_label.len - last_index_start_checkpoint >= 3
	if is_start_checkpoint && transaction_id.len > 0{
		log.values = transaction_id_match
		log.label = LogLabel.start_checkpoint
		return log
	}

	if is_start_transaction && transaction_id.len > 0 {
		log.transaction_id = transaction_id
		log.label = LogLabel.start_transaction
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
