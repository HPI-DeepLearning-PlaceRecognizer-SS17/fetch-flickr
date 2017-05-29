Flickr = require 'flickrapi'
FotoFetcher = require './FotoFetcher'
args = require('minimist')(process.argv.slice(2))
path = require 'path'
fs = require 'fs'

printUsage = ->
	console.log 'Usage:'
	console.log ' --flickrApiKey <apiKey>                       - your API key'
	console.log ' --flickrApiSecret <apiSecret>                 - you API secret'
	console.log ' --search "<searchTerm>"                       - word(s) to search for'
	console.log ' --dest "<directory>"          (default ./dl/) - destination download directory'
	console.log ' --resultsPerPage <int>        (default 10)    - images per page/query'
	console.log ' --maxPages <int>              (default 1)     - maximum number of pages to download'
	return

unless args.flickrApiKey? and args.flickrApiSecret? and args.search?
	printUsage()
	return

args.path ?= './dl/'
args.resultsPerPage ?= 10
args.maxPages ?= 1

downloadPath = path.resolve args.path
unless fs.existsSync(downloadPath)
	console.error 'ERROR: download directory does not exist'
	return

searchOptions = {
	resultsPerPage: Math.max 1, Math.min 100, Number.parseInt args.resultsPerPage
	maxPages: Math.max 1, Math.min 1000, Number.parseInt args.maxPages
}

if isNaN(searchOptions.resultsPerPage) or isNaN(searchOptions.maxPages)
	console.error 'ERROR: Invalid resultsPerPage / maxPages'
	return

flickrOptions = {
	api_key: args.flickrApiKey
	api_secret: args.flickrApiSecret
}

console.log 'Connecting to Flickr'

Flickr.tokenOnly flickrOptions, (error, flickr) ->
	if error?
		console.error 'ERROR: Unable to connect to Flickr'
		console.error error
		return

	console.log 'Connected to Flickr'

	fetcher = new FotoFetcher(flickr, downloadPath, searchOptions)

	searchPromise = fetcher.searchFor 'rotes rathaus'
	searchPromise = searchPromise.then (searchResult) =>
		downloadPage = (page) ->
			return fetcher.downloadPage searchResult, page
				.then (numberOfDownloadedPhotos) ->
					# Go immediately to next page if no photos were downloaded
					if numberOfDownloadedPhotos is 0
						return

					return new Promise (resolve) ->
						setTimeout(
							resolve
							Math.round Math.random() * 10000
						)
				.then -> if page < searchOptions.maxPages then downloadPage page + 1
				.catch (error) ->
					console.error "ERROR: Unable to download page #{page}"
					console.error error

		return downloadPage 1

	searchPromise = searchPromise.then ->
		console.log 'All pages downloaded'
		process.exit(0)

	searchPromise = searchPromise.catch (error) =>
		console.error "ERROR during download:"
		console.error error
		process.exit(1)