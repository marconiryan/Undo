module database

import json
import os
import db.pg
import log_undo

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
	db.exec('DROP TABLE IF EXISTS ${table_name}') or {
		panic(err)
	}
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
	db.exec(query) or {
		panic(err)
	}
}

pub fn undo(db pg.DB, table Table, undo_log log_undo.LogStructure) string{
	values_to_update := undo_log.values
	columns := table.table.keys()
	columns_to_update := values_to_update.filter(fn [columns] (val string) bool {
		return val in columns
	})

	mut query := "update ${table_name} set "

	if columns_to_update.len == 0 {
		return ""
	}

	for index,column in columns_to_update {
		query += "${column} = '${values_to_update[values_to_update.index(column) + 1]}'"
		if index > 0{
			query += " , "
		}
	}
	has_id := values_to_update.len % 2 != 0 && values_to_update.first() !in columns_to_update
	if has_id {
		query += " where id = '${values_to_update.first()}'"
	}

	println("--------------------- \nUNDO transação ${undo_log.transaction_id} \n")
	println("Realizando undo com ${query}")
	println("\n---------------------")
	db.exec(query) or {
		panic(err)
	}
	mut updated := ""

	for index,column in columns_to_update {
		updated += "${column} = '${values_to_update[values_to_update.index(column) + 1]}'"
		if index > 0{
			updated += " , "
		}
	}
	updated += "\n"
	return updated
}

pub fn display_old(table Table){
	current_table := table.table.clone()
	columns := current_table.keys()
	values := current_table.values()
	println("--------------------- \nTABLE ${table_name} (não atualizado)\n")
	println(columns.join("| "))
	for value in 0..values.first().len{
		for column in columns{
			current_value := table_type_to_string(current_table[column][value])
			print("${current_value}| ")
		}
		println("")
	}
	println("\n---------------------")
}

pub fn show_table(db pg.DB , table Table){
	current_table := table.table.clone()
	mut columns := current_table.keys()
	println("--------------------- \nTABLE ${table_name} (atualizada)\n")
	println("INFO: select ${columns.join(',')} from ${table_name}\n")
	println(columns.join("| "))


	query := db.exec("select ${columns.join(',')} from ${table_name} order by 1") or {
		panic(err)
	}
	values := query.map(fn (value pg.Row) []?string {
		return value.vals
	})

	for offset in 0..values.len{
		for index in  0..values.first().len{
			current_value := convert_to_string(values[offset][index])
			print("${current_value.str()}| ")
		}
		println("")
	}
	println("\n---------------------")

}

fn convert_to_string(a ?string) string{
	return a.str()
}
