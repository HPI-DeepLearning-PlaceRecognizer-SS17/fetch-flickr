Flickr = require 'flickr-sdk'
FotoFetcher = require './FotoFetcher'

flickr = new Flickr({
	apiKey: 'd29c7cf8599f69bfa464b5b12cc357d8'
	apiSecret: '6ad830727555b0c5'
})

fetcher = new FotoFetcher(flickr)

searchPromise = fetcher.searchFor 'Brandenburger Tor'
searchPromise = searchPromise.then (searchResult) =>
	return fetcher.downloadPage searchResult, 1

searchPromise.catch (error) =>
	console.error error
	throw error