module database

import json
import os

pub type TableType = bool | int | string

struct Table {
mut:
	table map[string][]TableType
}

struct Database {
	tables []Table
}

pub fn parse(data string) Table {
	return json.decode(Table, data) or { return Table{} }
}

pub fn parse_file(path string) Table {
	data := os.read_file(path) or { return Table{} }
	return parse(data)
}
