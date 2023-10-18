module main
import log
type TableType = int | string | bool

struct Table {
	name string
mut:
	columns map[string][]TableType
}

struct DataBase {
	tables [] Table
}

fn main() {
	table := Table{name: 'test', columns: {'asd' : ['1', '2', 12]}}
	println("Table: ${table.name}")

	for name,values in table.columns{
		println("Column: $name")
		println("Values: ${values}")

		for value in values {
			println(typeof(value))
		}

	}
}

