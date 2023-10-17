module main

struct Table {
	name string
mut:
	columns map[string][]string
}

struct DataBase {
	tables [] Table
}

fn main() {

	table := Table{name: 'test', columns: {'asd' : ['1', '2']}}

	println("Table: ${table.name}")

	for name,values in table.columns{
		println("Column: $name")
		println("Values: $values")
	}
}

