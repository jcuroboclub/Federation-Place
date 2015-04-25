# Federation Place Website
This is the actual hosted website.
The source code is located in `./src`.
When the page has been built with Gulp, the web page will be built in `./build`.

## Building
The main source layout was taken from [GreyPants' gulp-starter](https://github.com/greypants/gulp-starter#388267cb0c1cc4f41c06fc0db456e6629cc6d211).
In order to build the page, you will need to install [npm](https://www.npmjs.com/), see [here](https://docs.npmjs.com/getting-started/installing-node).
You will also need to install [gulp](gulpjs.com) using [these](https://github.com/gulpjs/gulp/blob/master/docs/getting-started.md) instructions
(although I'm fairly sure this will be automatically done later: please update this if you find out).

Next, you can install the project dependencies, using `npm install`.

Run `gulp iconFont` to generate the Facebook and Twitter logos, then just run `gulp`.
This will run a webserver and load the page for you.
It will also generate the page to `./build`.

## The Tools


## TODO

- ~~Basic Plotting~~
- ~~Pull data from ThingSpeak~~
- Abstract Data pulling for eventual use with eResearch system
- More useful plotting
- Floorplan layout
- Improve BDD (Behaviour Driven Development) coverage
- Take on some ideas from [GreyPants' gelp-starter update](https://github.com/greypants/gulp-starter/tree/2.0)