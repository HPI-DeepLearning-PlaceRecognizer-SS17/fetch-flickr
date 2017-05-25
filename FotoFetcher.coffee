fs = require 'fs'
path = require 'path'
http = require 'http'
download = require 'download'

class FotoFetcher

	constructor: (@flickrApi, @storagePath = 'dl') ->
		# https://www.flickr.com/services/api/misc.urls.html
		@photoSize = 'b'
		return

	searchFor: (searchTerm) =>
		debugger
		promise = @flickrApi.request().media().search(searchTerm).get({sort: 'relevance'})
		promise = promise.then (response) =>
			searchResult = {
				searchTerm: searchTerm
				numberOfPages: response.body.photos.pages
				photosPerPage: response.body.photos.perpage
			}

			totalPhotos = searchResult.numberOfPages * searchResult.photosPerPage
			console.log "Search for '#{searchTerm}' resulted in #{totalPhotos} Photos"
			return searchResult

		return promise

	downloadPage: (searchResult, page) =>
		console.log "Downloading page #{page} of #{searchResult.numberOfPages}"

		metadataPromise = @_fetchPhotosMetadata searchResult, page
		downloadPromise = metadataPromise.then (photos) =>
			debugger
			notDownloadedPhotos = @_storeMetadata photos
			return @_downloadPhotos notDownloadedPhotos
		return downloadPromise

	_fetchPhotosMetadata: (searchResult, page) =>
		console.log "Fetching page metadata"
		promise = @flickrApi.request().media().search(searchResult.searchTerm).get({page: page})
		promise = promise.then (response) =>
			console.log "Page metadata fetched"
			return response.body.photos.photo
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
				fs.writeFileSync jsonFilename, JSON.stringify photo

		return newlyStored

	_downloadPhotos: (photos) =>
		promises = photos.map @_downloadPhoto
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