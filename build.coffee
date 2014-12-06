glob       = require 'glob'
path       = require 'path'
fs         = require 'fs-extra'
mime       = require 'mime'
moment     = require 'moment'
_          = require 'lodash'

image_size = require 'image-size'

# PHP
php        = require 'phpjs'

# YAML
YAML       = require 'yamljs'

# Vars
out = './out'


# Utils
write = (data, out_file, rw = false) ->
	fs.ensureDir path.dirname out_file, (err) ->
		console.error 'ERROR create dir ' + path.dirname out_file
	fs.exists out_file, (exist) ->
		if exist and rw == true or !exist
			fs.outputFile out_file , data, 'utf8', (err) ->
				console.error 'ERROR during Write the file ' + out_file + ' ' + err if err


# readJSON

Posts = fs.readJsonSync './PostsSort.json'

console.log _(Posts).pluck('post_title').value()