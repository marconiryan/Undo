module database

import json
import os
import db.pg
import log

pub type TableType = bool | int | string
const (
	table_name = 'undo_log'
)

fn table_type_to_string(val TableType) string {
	match val {
		string {
			return val
		}
		bool {
			return val.str()
		}
		int {
			return val.str()
		}
	}
}


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

pub fn setup(path string) pg.DB{
	data_env := os.read_file("env.json")  or {
		panic(err)
	}
	config := json.decode(pg.Config, data_env) or {
		panic(err)
	}
	table := parse_file(path)
	table_columns := table.table.keys()


	db := pg.connect(config) or {
		panic(err)
	}
	reset(db)
	create(db, table_columns)
	setup_insert(db,table)
	return db
}

fn reset(db pg.DB){
	db.exec('DROP TABLE IF EXISTS ${table_name}') or {return}
}
fn create(db pg.DB, columns []string){
	if columns.len <= 0{
		return
	}
	mut create_table := "CREATE TABLE ${table_name}("

	for index,column in columns{
		if index == columns.len -1 {
			create_table += "${column} text"
			continue
		}
		create_table += "${column} text,"
	}
	create_table += ");"

	db.exec(create_table) or {
		panic(err)
	}
}

fn setup_insert(db pg.DB,table Table){
	columns := table.table.keys()
	mut query := "insert into ${table_name} ("
	for index,column in columns{
		if index == columns.len -1 {
			query += "${column})"
			continue
		}
		query += "${column},"
	}

	query += " values "
	values_len := table.table[columns.first()].len

	for index_value in 0..values_len{
		query += "("
		for index_column, column in columns{
			value  :=table.table[column][index_value]
			if index_column == columns.len -1 {
				query += "'${table_type_to_string(value)}'"
				continue
			}
			query += "'${table_type_to_string(value)}',"
		}
		if index_value == values_len -1 {
			query += ");"
			continue
		}
		query += "), "
	}
	db.exec(query) or {return}
}

pub fn undo(db pg.DB, table Table, rollback_log log.LogStructure){
	values_to_update := rollback_log.values
	columns := table.table.keys()
	columns_to_update := values_to_update.filter(fn [columns] (val string) bool {
		return val in columns
	})

	mut query := "update ${table_name} set "

	for index,column in columns_to_update {
		query += "${column} = '${values_to_update[columns.index(column)]}'"
		if index > 0{
			query += " , "
		}
	}
	has_id := values_to_update.len % 2 != 0 && values_to_update.first() !in columns_to_update
	if has_id {
		query += " where id = ${values_to_update.first()}"
	}

	db.exec(query) or {return }
}
