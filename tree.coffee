glob     = require 'glob'
path     = require 'path'
fs       = require 'fs-extra'
mime     = require 'mime'
moment   = require 'moment'
_        = require 'lodash'

image_size = require 'image-size'

url      = require 'url'

# PHP
php         = require 'phpjs'


# Vars
base = './build'
# uploads_dir = 'http://abnmt.com/komedianty/wp-content/uploads/'
# old_url     = 'http://abnmt.com/komedianty/'

uploads_dir = 'http://komedianty.com/content/uploads/'
url         = 'http://komedianty.com/'
old_url     = 'http://komedianty.com'

uprel       = uploads_dir
rel         = old_url

# uprel       = "http://komedianty.com/content/uploads/"
# rel         = "http://komedianty.com"

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


# READ DIR

types = fs.readdirSync(base)
list = glob.sync "#{base}/**/*"

posts = {}

_(list).forEachRight (entry) ->
	# console.log entry
	# // entry -> 'base\\type\\directory\\file.ext'
	ID            = (path.relative base, path.dirname entry).replace(/\\/g, '/') # 'type/directory'
	entryPathName = (path.relative base, entry).replace(/\\/g, '/')              # 'type/directory/file.ext'
	entryExt      = path.extname entry                                           # '.ext'
	entryBasename = path.basename(entry)                                         # 'file.ext'
	entryName     = path.basename(entry, entryExt)                               # 'file'

	posts[ID] = {} if not posts[ID] and ID not in types and ID != ""

	switch entryExt
		when '.jpeg', '.jpg', '.gif', '.png'
			image = {}

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

			# Postmeta
			posts[ID].postmeta = postmeta



_(posts).forEachRight (post, ID) ->
	# console.log '\n\n ===', ID
	if post.post_content
		post.post_content = post.post_content.replace /(href|src)=\"(.+?)\"/g, (string, p1, p2) ->
			# console.log p2
			if p1 is 'href' and p2.search(/^http\:/) is -1
				return "href=\"#{url}" + (path.relative '.', (path.resolve ID, p2)).replace(/\\/g, '/') + "\""
			else if p1 is 'src'
				return "src=\"#{uploads_dir}" + (path.relative '.', (path.resolve ID, p2)).replace(/\\/g, '/') + "\""
			else if p1 is 'href' and p2.search(/^http\:/) is 0
				if p2.search(/^http\:\/\/komedianty\.com/) is 0
					console.log str = path.basename (path.relative 'http://komedianty.com/ru/truppa/', p2), '.html'
					if str.search(/^\d+/) is 0
						console.log str = str.match(/(\d+).+/)
						if str[1]
							console.log str = str[1]
							_(posts).forEach (post, postID) ->
								if post.postmeta.jos_id == str
									# console.log postID
									return "href=\"#{url}" + (path.relative '.', (path.resolve ID, postID)).replace(/\\/g, '/') + "\""
				else
					return string




fs.writeJSON 'Posts.json', posts, (err, data) ->
	console.log err if err


###
		image.ID = ID
		image.post_title     = "#{post.post_title} (Фото)"


		image.post_date         = post.post_date
		image.post_date_gmt     = post.post_date_gmt
		image.post_modified     = post.post_modified
		image.post_modified_gmt = post.post_modified_gmt

###