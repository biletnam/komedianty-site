glob     = require 'glob'
path     = require 'path'
fs       = require 'fs-extra'
dir      = require 'read-dir-files'
mime     = require 'mime'
moment   = require 'moment'
_        = require 'lodash'

image_size = require 'image-size'

url      = require 'url'
url.join = require 'url-join'

# PHP
php         = require 'phpjs'


# Vars
base = 'build'
# uploads_dir = 'http://abnmt.com/komedianty/wp-content/uploads/'
# old_url     = 'http://abnmt.com/komedianty/'

uploads_dir = 'http://komedianty.com/content/uploads/'
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


readSync = (dir, encoding = 'utf-8', recursive = true) ->
	result = {}

	entries = fs.readdirSync(dir)
	entries.forEach (entry) ->
		entryPath = path.join(dir, entry)
		entryExt  = path.extname entry
		entryName = path.basename entry, entryExt

		if fs.statSync(entryPath).isDirectory()
			return recursive and (result[entry] = readSync(entryPath))

		switch entryExt
			when '.json'
				return result[entryName] = fs.readJSONSync(entryPath, 'utf-8')
			when '.link'
				return result[entryName] = fs.readFileSync(entryPath, 'utf-8')
			when '.jpeg', '.jpg', '.gif', '.png'
				result['images'] = {} if not result['images']
				# img = {}
				# img[entryName] = entryPath
				return result['images'][entryName] = entryPath
				# return result[entryName]['images'].push entryPath
			when '.md'
				return result[entryName] = md.render(fs.readFileSync(entryPath, 'utf-8'))


	result

posts = readSync(base)

fs.writeJSON 'readDirs.json', posts, (err, data) ->
	console.log err if err


# Data
ID = 1

image_list = []

add_data = (object) ->
	_.forEachRight object, (types, post_type) ->
		_(types).forEach (post, post_name) -> post.post_name = post_name
		_(types).forEach (post) -> post.sort = parseInt(moment( post.postmeta.date ).format('X'))
		_(types).sortBy('sort').forEach (post) ->

			# console.log post

			delete post.sort

			post.ID = ID
			ID++

			# Title
			post.post_title = post.postmeta.title
			delete post.postmeta.title

			# Name
			post_name = post.post_name
			delete post.post_name
			post.post_name = post_name

			# Type
			post.post_type = post_type

			# Content
			post.post_content = post.content
			delete post.content

			# Excerpt
			if post.postmeta.synopsis
				post.post_excerpt = post.postmeta.synopsis
				delete post.postmeta.synopsis

			# Date
			date = post.postmeta.date
			post.post_date         = moment(date).format("YYYY-MM-DD HH:mm:ss")
			post.post_date_gmt     = moment(post.post_date).zone('0').format("YYYY-MM-DD HH:mm:ss")
			post.post_modified     = post.post_date
			post.post_modified_gmt = post.post_date_gmt
			delete post.postmeta.date

			# Postmeta
			postmeta = []
			_(post.postmeta).forEach (value, key) ->
				# console.log meta, key
				meta ={}

				meta.post_id = post.ID
				meta.meta_key = key

				switch key
					when "employment"
						_(value).forEach (obj) ->
							delete obj.performance_id if obj.performance_id

				meta.meta_value = value if _.isString(value)
				meta.meta_value = php.serialize value if _.isArray(value) or _.isObject(value)

				postmeta.push meta

			post.postmeta = postmeta if post.postmeta

			# Images
			images = []
			_(post.images).forEach (image, key) ->
				# console.log image, key
				img = {}

				img.ID = ID
				ID++

				img.post_name      = key
				img.post_title     = "#{post.post_title} (Фото)"

				img.post_parent    = post.ID

				img.post_status    = "inherit"
				img.post_type      = "attachment"
				img.post_mime_type = mime.lookup image

				img.post_date         = post.post_date
				img.post_date_gmt     = post.post_date_gmt
				img.post_modified     = post.post_modified
				img.post_modified_gmt = post.post_modified_gmt

				img.guid              = url.join(uprel, path.relative(base, image)).replace(/\\/g, '/')

				# img_meta
				img.postmeta = []
				_(['_wp_attached_file', '_wp_attachment_metadata']).forEach (key) ->
					meta = {}
					meta.post_id = img.ID
					meta.meta_key = key

					switch key
						when "_wp_attached_file"
							value = (path.relative uploads_dir, img.guid).replace(/\\/g, '/')
						when "_wp_attachment_metadata"
							value = {}
							dims = image_size path.join(base, (path.relative uploads_dir, img.guid))
							value.width = dims.width
							value.height = dims.height
							value.file = (path.relative uploads_dir, img.guid).replace(/\\/g, '/')
							# value.sizes = {}
							# value.image_meta = {}


					meta.meta_value = value if _.isString(value)
					meta.meta_value = php.serialize value if _.isArray(value) or _.isObject(value)

					img.postmeta.push meta

				images.push img

				# Fot thumbs
				image_list.push img

			post.images = images if post.images

# add_data posts

add_thumb = (object) ->
	_.forEachRight object, (types, post_type) ->
		_(types).forEach (post) ->
			# Thumb
			# thumb = post.thumbnail if post.thumbnail
			# thumb = post.portrait if post.portrait
			# thumb = post.poster if post.poster
			if thumb = post.thumbnail or thumb = post.portrait or thumb = post.poster
				imgID = _(image_list).where({"guid":thumb}).pluck('ID').value().pop()
				post.postmeta.push {"post_id":post.ID, "meta_key": "_thumbnail_id", "meta_value":imgID}
			delete post.thumbnail if post.thumbnail
			delete post.portrait if post.portrait
			delete post.poster if post.poster


# add_thumb posts

# fs.writeJSON 'posts.json', posts, (err, data) ->
# 	console.log err if err

# console.log posts

sql_content = []

sql = (posts) ->
	_(posts).forEach (type) ->
		#  POSTS
		keys = []
		_(type).forEach (post) -> _.merge keys, _.keys(post)
		keys = _.difference keys, ['images', 'postmeta']
		insert = "\nINSERT INTO `kt_posts` (`#{keys.join('`, `')}`) VALUES"

		values = []
		_(type).forEach (post) ->
			contents = []
			_(keys).forEach (key) ->
				if post[key]
					post[key] = post[key].replace(/\n|\r\n/g, "\\n") if key in ['post_content', 'post_excerpt']
					contents.push "\'#{post[key]}\'" if _.isString(post[key])
					contents.push "#{post[key]}" if _.isNumber(post[key])
					# contents.push "\'\'" if _.isNaN
				else
					contents.push "\'\'"

			values.push "(#{contents.join(", ")})"

		values = "#{values.join(",\n")};"
		sql_content.push "#{insert}\n#{values}\n"


		# POSTS_META
		_(type).forEach (post) ->
			if post.postmeta
				postmeta_keys = []
				_(post.postmeta).forEach (postmeta) -> _.merge postmeta_keys, _.keys(postmeta)
				postmeta_insert = "\nINSERT INTO `kt_postmeta` (`#{postmeta_keys.join('`, `')}`) VALUES"

				postmeta_values = []
				_(post.postmeta).forEach (postmeta) ->
					postmeta_contents = []
					_(postmeta_keys).forEach (key) ->
						if postmeta[key]
							postmeta_contents.push "\'#{postmeta[key]}\'" if _.isString(postmeta[key])
							postmeta_contents.push "#{postmeta[key]}" if _.isNumber(postmeta[key])
						else
							postmeta_contents.push "\'\'"
					postmeta_values.push "(#{postmeta_contents.join(", ")})"

				postmeta_values = "#{postmeta_values.join(",\n")};"

				sql_content.push "#{postmeta_insert}\n#{postmeta_values}\n"


		# IMAGES
		_(type).forEach (post) ->
			if post.images
				images_keys = []
				_(post.images).forEach (image) ->
					_.merge images_keys, _.keys(image)
				images_keys = _.difference images_keys, ['postmeta']
				images_insert = "\nINSERT INTO `kt_posts` (`#{images_keys.join('`, `')}`) VALUES"

				images_values = []
				_(post.images).forEach (image) ->
					images_contents = []
					_(images_keys).forEach (key) ->
						if image[key]
							images_contents.push "\'#{image[key]}\'" if _.isString(image[key])
							images_contents.push "#{image[key]}" if _.isNumber(image[key])
						else
							images_contents.push "\'\'"
					images_values.push "(#{images_contents.join(", ")})"

				images_values = "#{images_values.join(",\n")};"

				sql_content.push "#{images_insert}\n#{images_values}\n"


				# IMAGES_META
				_(post.images).forEach (image) ->
					if image.postmeta
						postmeta_keys = []
						_(image.postmeta).forEach (postmeta) -> _.merge postmeta_keys, _.keys(postmeta)
						postmeta_insert = "\nINSERT INTO `kt_postmeta` (`#{postmeta_keys.join('`, `')}`) VALUES"

						postmeta_values = []
						_(image.postmeta).forEach (postmeta) ->
							postmeta_contents = []
							_(postmeta_keys).forEach (key) ->
								if postmeta[key]
									postmeta_contents.push "\'#{postmeta[key]}\'" if _.isString(postmeta[key])
									postmeta_contents.push "#{postmeta[key]}" if _.isNumber(postmeta[key])
								else
									postmeta_contents.push "\'\'"
							postmeta_values.push "(#{postmeta_contents.join(", ")})"

						postmeta_values = "#{postmeta_values.join(",\n")};"

						sql_content.push "#{postmeta_insert}\n#{postmeta_values}\n"

# sql posts

# sql_in = '''
# TRUNCATE `kt_postmeta`;
# TRUNCATE `kt_posts`;
# '''

# fs.writeFile 'sql.sql', sql_in + sql_content.join("\n"), (err, data) ->
# 	console.log err if err