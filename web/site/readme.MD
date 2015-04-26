# Federation Place Website
This is the actual hosted website.
The source code is located in `./src/`.
When the page has been built with Gulp, the web page will be built in `./build/`.

## Building
The main source layout was taken from [GreyPants' gulp-starter](https://github.com/greypants/gulp-starter#388267cb0c1cc4f41c06fc0db456e6629cc6d211).
In order to build the page, you will need to install [npm](https://www.npmjs.com/), see [here](https://docs.npmjs.com/getting-started/installing-node).
You will also need to install [gulp](gulpjs.com) using [these](https://github.com/gulpjs/gulp/blob/master/docs/getting-started.md) instructions
(although I'm fairly sure this will be automatically done later: please update this if you find out).

Next, you can install the project dependencies, using `npm install`.

Run `gulp iconFont` to generate the Facebook and Twitter logos, then just run `gulp`.
This will run a webserver and load the page for you.
It will also generate the page to `./build/`.

## The Tools
### Gulp
The project uses [gulp](gulpjs.com) for building.
The gulp configurations are contained within `./gulp/`.
`./gulp/config.js` contains the high-level configurations, as to which files are important to various tasks.
The tasks themselves are located within `./gulp/tasks/`, and contain the specific code to complete various build tasks, such as converting CoffeeScript to JavaScript, bundling the files together, and moving them to `./build`.
Other tasks are in charge of running tests, code checks (linting), sass->css, and uglifying.

### CoffeeScript and Browserify
The code is written in CoffeeScript, which compiles to JavaScript but makes easy some of JavaScript's ugly idioms.
Browserify allows you to `require` code, meaning you can easily separate the code out and modularise it.
At the end, gulp/browserify simply bundles the required code into a single file.
Gulp automatically compiles the code to JavaScript too, and places it in `./build`.

### D3 and NVD3
[D3](d3js.org) is a visualisation library, that allows you to easily bind data to svg elements.
[NVD3](http://nvd3.org/) is built on D3, and provides basic, ready-built graphs for use.

### Karma, Mocha and Chai
[Chai](http://chaijs.com/) is a BDD (Behaviour Driven Development)/TDD (Test Driven Development) library, which allows you to run tests to ensure you don't break your code as you change/develop it.
Its commands allow you to define assertions, defining low level behaviour.
[Mocha](http://mochajs.org/) is a test framework for JavaScript, at a higher level than Chai.
Its commands are structured in such a way that you can easily define how an object should behave, then ensure you are programming it to do so correctly.
Finally, [Karma](http://karma-runner.github.io/) is a test runner, which allows you to continuously run test as you code.
In this project, Karma is configured to run all Mocha tests, located in `./src/javascript/__tests__/`.
The Mocha tests, in turn, use Chai commands to make the assertions.

## TODO

- ~~Basic Plotting~~
- ~~Pull data from ThingSpeak~~
- Abstract Data pulling for eventual use with eResearch system
- More useful plotting
- Floorplan layout
- Improve BDD (Behaviour Driven Development) coverage
- Take on some ideas from [GreyPants' gelp-starter update](https://github.com/greypants/gulp-starter/tree/2.0)