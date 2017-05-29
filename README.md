# fetch-flickr

Download images from flickr by searching for a specific term.

## Installation

1. Install node.js
2. Clone this repo
3. Run `npm install` to get all required dependencies
4. Get your Flickr API key [here](https://www.flickr.com/services/apps/create/)

## Usage

`$ node index.js <arguments>`

with arguments being

```
Usage:
 --flickrApiKey <apiKey>                       - your API key
 --flickrApiSecret <apiSecret>                 - you API secret
 --search "<searchTerm>"                       - word(s) to search for
 --dest "<directory>"          (default ./dl/) - destination download directory
 --resultsPerPage <int>        (default 10)    - images per page/query
 --maxPages <int>              (default 1)     - maximum number of pages to download
```
