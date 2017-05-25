fs = require 'fs'
path = require 'path'
http = require 'http'
download = require 'download'

class FotoFetcher

	constructor: (@flickrApi, @storagePath = 'dl') ->
		# https://www.flickr.com/services/api/misc.urls.html
		@photoSize = 'b'
		return

	_searchPhotos: (searchTerm, page) =>
		searchOptions = {
			text: searchTerm
			sort: 'relevance'
			media: 'photos'
			per_page: 10
			parse_tags: 1
			content_type: 7
			lang: 'de-DE'
			extras: 'description, license, date_upload, date_taken, owner_name, icon_server, original_format, last_update, geo, tags, machine_tags, o_dims, views, media, path_alias, url_sq, url_t, url_s, url_q, url_m, url_n, url_z, url_c, url_l, url_o'
		}

		if page?
			searchOptions.page = page

		promise = new Promise (resolve, reject) =>
			debugger
			@flickrApi.photos.search(
				searchOptions,
				(error, result) ->
					if error
						return reject error
					resolve result.photos
			)

		return promise

	searchFor: (searchTerm) =>
		promise = @_searchPhotos searchTerm

		promise = promise.then (photos) =>
			searchResult = {
				searchTerm: searchTerm
				numberOfPages: photos.pages
				photosPerPage: photos.perpage
			}

			console.log "Search for '#{searchTerm}' resulted in #{photos.total} Photos"
			return searchResult

		return promise

	downloadPage: (searchResult, page) =>
		console.log "Downloading page #{page} of #{searchResult.numberOfPages}"

		metadataPromise = @_fetchPhotosMetadata searchResult, page
		downloadPromise = metadataPromise.then (photos) =>
			notDownloadedPhotos = @_storeMetadata photos
			return @_downloadPhotos notDownloadedPhotos
		downloadPromise = downloadPromise.then ->
			console.log "Downloaded page #{page}"
			return
		return downloadPromise

	_fetchPhotosMetadata: (searchResult, page) =>
		console.log "Fetching page metadata"
		promise = @_searchPhotos searchResult.searchTerm, page
		promise = promise.then (photos) =>
			console.log "Page metadata fetched"
			photos = photos.photo

			for photo in photos
				photo._fetchFlickr = {
					searchResult: searchResult
					page: page
				}
			return photos
		return promise

	_storeMetadata: (photos) =>
		newlyStored = []

		for photo in photos
			jsonFilename = @_storageFileNameForPhoto(photo) + '.json'
			fotoFilename = @_storageFileNameForPhoto(photo) + '.jpg'

			if fs.existsSync(jsonFilename) and fs.existsSync(fotoFilename)
				console.log "Skipping download of photo '#{photo.id}' (already exists)"
				continue

			newlyStored.push photo
			unless fs.existsSync(jsonFilename)
				fs.writeFileSync jsonFilename, JSON.stringify photo, true, 2

		return newlyStored

	_downloadPhotos: (photos) =>
		promises = photos.map (photo) =>
			return new Promise (resolve) =>
				setTimeout(
					=> resolve @_downloadPhoto(photo)
					Math.round Math.random() * 5000
				)
		return Promise.all promises

	_downloadPhoto: (photo) =>
		url = "https://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_#{@photoSize}.jpg"
		return download(url, @storagePath, { filename: photo.id + '.jpg' })
		.then ->
			console.log "Downloaded photo '#{photo.id}'"
		.catch (error) ->
			console.error "ERROR: Unable to download photo '#{photo.id}'"
			console.error error

	_storageFileNameForPhoto: (photo) =>
		return path.normalize path.join @storagePath, photo.id

module.exports = FotoFetcher