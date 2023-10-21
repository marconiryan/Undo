module main

import database
import log

fn main() {
	data := '{
		"table": {
				"id":[1,2],
				"A": [20,20],
				"B": [55,30]
  				}
			}'
	table_using_string := database.parse(data)
	println(table_using_string)
	table_using_file := database.parse_file('./meta.json')
	println(table_using_file)
	log.parse('./file.log')

}
