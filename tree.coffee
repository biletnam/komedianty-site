glob     = require 'glob'
path     = require 'path'
fs       = require 'fs-extra'
mime     = require 'mime'
moment   = require 'moment'
_        = require 'lodash'

image_size = require 'image-size'

# PHP
php         = require 'phpjs'


# Vars
base = './build'


uploads_dir = 'http://abnmt.com/komedianty/wp-content/uploads/'
url     = 'http://abnmt.com/komedianty/'

# uploads_dir = 'http://komedianty.com/content/uploads/'
# url         = 'http://komedianty.com/'


upload = 'http://'
# base = 'build\\event'

# Markdown
Remarkable  = require 'remarkable'
md = new Remarkable(
	html: true              # Enable HTML tags in source
	xhtmlOut: false         # Use '/' to close single tags (<br />)
	breaks: true            # Convert '\n' in paragraphs into <br>
	langPrefix: "language-" # CSS language prefix for fenced blocks
	linkify: true           # Autoconvert URL-like text to links
	typographer:  true
	quotes: '«»‘’'
)



# Utils
write = (data, out_file, rw = false) ->
	fs.ensureDir path.dirname out_file, (err) ->
		console.error 'ERROR create dir ' + path.dirname out_file
	fs.exists out_file, (exist) ->
		if exist and rw == true or !exist
			fs.outputFile out_file , data, 'utf8', (err) ->
				console.error 'ERROR during Write the file ' + out_file + ' ' + err if err




# READ DIR

types = fs.readdirSync(base)
list = glob.sync "#{base}/**/*"

scheme =
	ID: 0
	post_title: ''
	post_name: ''
	post_type: ''
	post_content: ''

posts = {}

_(list).forEach (entry) ->
	# console.log entry
	# // entry -> 'base\\type\\directory\\file.ext'
	ID            = (path.relative base, path.dirname entry).replace(/\\/g, '/') # 'type/directory'
	entryPathName = (path.relative base, entry).replace(/\\/g, '/')              # 'type/directory/file.ext'
	entryExt      = path.extname entry                                           # '.ext'
	entryBasename = path.basename(entry)                                         # 'file.ext'
	entryName     = path.basename(entry, entryExt)                               # 'file'

	posts[ID] = _.clone(scheme) if not posts[ID] and ID not in types and ID != ""

	switch entryExt
		when '.jpeg', '.jpg', '.gif', '.png'
			image = {}

			image.ID = 0
			image.gID = ID

			image.guid           = uploads_dir + entryPathName
			image.post_name      = entryBasename

			image.post_mime_type = mime.lookup entry
			image.post_status    = "inherit"
			image.post_type      = "attachment"

			image.post_parent    = ID


			image.postmeta = {}

			imageMeta = {}
			dims = image_size entry
			imageMeta.width  = dims.width
			imageMeta.height = dims.height
			imageMeta.file   = entryPathName

			image.postmeta['_wp_attached_file']       = entryPathName
			image.postmeta['_wp_attachment_metadata'] = imageMeta

			posts[entryPathName] = image



		when '.md'
			posts[ID].post_content = md.render(fs.readFileSync(entry, 'utf-8'))
		when '.html'
			posts[ID].post_content = fs.readFileSync(entry, 'utf-8')



		when '.json'
			postmeta = fs.readJSONSync(entry, 'utf-8')

			# gID
			posts[ID].ID = 0
			posts[ID].gID = ID
			posts[ID].guid = url + ID

			# Title
			posts[ID].post_title = postmeta.title
			delete postmeta.title

			# Name
			posts[ID].post_name = ID.split('/').pop()

			# Type
			posts[ID].post_type = ID.split('/').shift() if ID.split('/').shift() in types

			# PostParent
			if ID.split('/').length > 2
				arr = ID.split('/')
				posts[ID].post_parent = arr.slice(0,arr.length-1).join('/')

			# Excerpt
			if postmeta.synopsis
				posts[ID].post_excerpt = postmeta.synopsis
				delete postmeta.synopsis

			# Date
			posts[ID].post_date         = moment(postmeta.date).format("YYYY-MM-DD HH:mm:ss")
			posts[ID].post_date_gmt     = moment(posts[ID].post_date).zone('0').format("YYYY-MM-DD HH:mm:ss")
			posts[ID].post_modified     = posts[ID].post_date
			posts[ID].post_modified_gmt = posts[ID].post_date_gmt
			delete postmeta.date

			# SORT
			posts[ID].sort = parseInt(moment(posts[ID].post_date).format("X"))

			# Postmeta
			posts[ID].postmeta = postmeta

			# Publish
			posts[ID].post_status = 'publish'

			# Menu order
			posts[ID].menu_order = postmeta.menu_order if postmeta.menu_order


# FIX LINKS
outlinks = {}

_(posts).forEach (post, ID) ->
	# console.log '\n\n ===', ID
	if post.post_content
		post.post_content = post.post_content.replace /(href|src)=\"(.+?)\"/g, (string, p1, p2) ->
			# console.log p2
			if p1 is 'href' and p2.search(/^http\:/) is -1
				return "href=\"#{url}" + (path.relative '.', (path.resolve ID, p2)).replace(/\\/g, '/') + "\""
			else if p1 is 'src'
				return "src=\"#{uploads_dir}" + (path.relative '.', (path.resolve ID, p2)).replace(/\\/g, '/') + "\""
			else if p1 is 'href' and p2.search(/^http\:/) is 0
				outlinks[ID] = [] if not outlinks[ID]
				outlinks[ID].push p2
				return string




fs.writeJSON 'Posts.json', posts, (err, data) ->
	console.log err if err
fs.writeJSON 'Outlinks.json', outlinks, (err, data) ->
	console.log err if err



# ADD ID
ID = 1
postsSort = []
_(posts).where("sort").sortBy('sort').forEach (post) ->
	post.ID = ID
	ID++
	postsSort.push post
	_(posts).where({"post_parent":post.gID, "post_date":undefined}).sortBy('post_name').forEach (image, igID) ->
		image.ID = ID
		image.post_parent = post.ID
		ID++
		postsSort.push image
	_(posts).where({"post_parent":post.gID}).sortBy('sort').forEach (child, chID) ->
		child.post_parent = post.ID

# REPLACE PARENTS
### TODO: fix not page parents ###
# _(postsSort).forEach (post) ->
# 	if _.isString(post.post_parent)
# 		post.post_parent = _(postsSort).where({"gID":post.post_parent}).pluck('ID').value().pop()

fs.writeJSON 'PostsSort.json', postsSort, (err, data) ->
	console.log err if err




# TO SQL

post_keys = []
# o = 0
# _(postsSort).forEach (post) ->
# _(postsSort).first(20).forEach (post) ->
# 	o++
# 	console.log '\n\n===', o, '==='
# 	console.log post_keys
# 	console.log _.keys post
# 	_.merge post_keys, _.keys(post)
# 	console.log post_keys
# 	console.log '===\n\n'
# console.log post_keys
# console.log post_keys

_(postsSort).first(20).forEach (post) ->
	post_keys = post_keys.concat _.keys(post)

post_keys = _.uniq post_keys
post_keys = _.difference post_keys, ['gID', 'sort', 'postmeta']

console.log post_keys
#  ?????

# post_keys = [
# 	'ID',
# 	'post_title',
# 	'post_name',
# 	'post_type',
# 	'guid',
# 	'post_mime_type',
# 	'post_status',
# 	'post_parent',
# 	'post_date',
# 	'post_date_gmt',
# 	'post_modified',
# 	'post_modified_gmt',
# 	'post_content'
# ]

# POSTMETA

postmetaSort = []

_(postsSort).where('postmeta').forEach (post) ->
	_(post.postmeta).forEach (value, key) ->
		meta = {}
		meta.post_id = post.ID
		meta.meta_key = key
		meta.meta_value = value
		if _.isString meta.meta_value
			meta.meta_value = meta.meta_value.replace /\n|\r\n/g, "\\n"
			meta.meta_value = meta.meta_value.replace /\'/g, "\\'"
		if _.isPlainObject meta.meta_value
			meta.meta_value = php.serialize meta.meta_value
		postmetaSort.push meta


toSQL = (table, keys, data, step = 50) ->
	i = 0
	k = 0
	scope = []
	count = data.length
	result = []

	insert = "\nINSERT INTO `#{table}` (`#{keys.join('`, `')}`) VALUES\n"

	_(data).forEach (post) ->
		k++
		values = []
		_(keys).forEach (post_key) ->
			if post[post_key]
				value = post[post_key]
				if _.isString value
					value = value.replace /\n|\r\n/g, "\\n"
					value = value.replace /\'/g, "\\'"
				if _.isPlainObject value
					value = php.serialize value
				values.push "\'#{value}\'"
			else
				values.push "\'\'"
		values = "(#{values.join(', ')})"
		if i < step
			scope.push values
			i++
		if i == step or k == count
			i = 0
			result.push "#{insert}#{scope.join(",\n")};"
			scope = []
	return result.join("\n")





sql = "TRUNCATE `kt_postmeta`;\nTRUNCATE `kt_posts`;\n" + toSQL('kt_posts', post_keys, postsSort, 75) + toSQL('kt_postmeta', ['post_id', 'meta_key', 'meta_value'], postmetaSort, 75)
write sql, 'sql.sql', true





###
		image.ID = ID
		image.post_title     = "#{post.post_title} (Фото)"


		image.post_date         = post.post_date
		image.post_date_gmt     = post.post_date_gmt
		image.post_modified     = post.post_modified
		image.post_modified_gmt = post.post_modified_gmt

###