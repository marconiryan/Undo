module log

import database

[flag]
enum TransactionStatus {
	unprocessed
	processed
	aborted
	ignored
}

struct Transaction {
	started        bool
	committed      bool
	transaction_id string
	table_id       string [skip]
	values         map[string]database.TableType
}
