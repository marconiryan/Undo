module main

import log

fn main() {
	data := '{
		"table": {
				"id":[1,2],
				"A": [20,20],
				"B": [55,30]
  				}
			}'
	table_using_string := log.parse(data)
	println(table_using_string)
	table_using_file := log.parse_file('./meta.json')
	println(table_using_file)
}
