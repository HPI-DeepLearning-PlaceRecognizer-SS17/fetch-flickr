Flickr = require 'flickrapi'
FotoFetcher = require './FotoFetcher'

flickrOptions = {
	api_key: 'd29c7cf8599f69bfa464b5b12cc357d8'
	api_secret: '6ad830727555b0c5'
}

console.log 'Connecting to Flickr'

Flickr.tokenOnly flickrOptions, (error, flickr) ->
	if error?
		console.error 'ERROR: Unable to connect to Flickr'
		console.error
		return
	console.log 'Connected to Flickr'

	fetcher = new FotoFetcher(flickr)

	searchPromise = fetcher.searchFor 'reichstag berlin'
	searchPromise = searchPromise.then (searchResult) =>
		downloadPage = (page) ->
			return fetcher.downloadPage searchResult, page
				.then ->
					return new Promise (resolve) ->
						setTimeout(
							resolve
							Math.round Math.random() * 10000
						)
				.then -> downloadPage page + 1
				.catch (error) ->
					console.error "ERROR: Unable to download page #{page}"
					console.error error

		return downloadPage 1

	searchPromise.catch (error) =>
		console.error error
		throw error