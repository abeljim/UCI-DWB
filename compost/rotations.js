var myIndex = 0;
var result1 = 0; //prev value
var result2 = 0; //new value
var readFlag;
carousel();
runProgram();
function sleep(ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
}
var CountUp = function(target, startVal, endVal, decimals, duration, options) {

	var self = this;
	self.version = function () { return '1.9.3'; };

	// default options
	self.options = {
		useEasing: true, // toggle easing
		useGrouping: true, // 1,000,000 vs 1000000
		separator: ',', // character to use as a separator
		decimal: '.', // character to use as a decimal
		easingFn: easeOutExpo, // optional custom easing function, default is Robert Penner's easeOutExpo
		formattingFn: formatNumber, // optional custom formatting function, default is formatNumber above
		prefix: '', // optional text before the result
		suffix: '', // optional text after the result
		numerals: [] // optionally pass an array of custom numerals for 0-9
	};

	// extend default options with passed options object
	if (options && typeof options === 'object') {
		for (var key in self.options) {
			if (options.hasOwnProperty(key) && options[key] !== null) {
				self.options[key] = options[key];
			}
		}
	}

	if (self.options.separator === '') {
		self.options.useGrouping = false;
	}
	else {
		// ensure the separator is a string (formatNumber assumes this)
		self.options.separator = '' + self.options.separator;
	}

	// make sure requestAnimationFrame and cancelAnimationFrame are defined
	// polyfill for browsers without native support
	// by Opera engineer Erik Möller
	var lastTime = 0;
	var vendors = ['webkit', 'moz', 'ms', 'o'];
	for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
		window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
		window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame'] || window[vendors[x]+'CancelRequestAnimationFrame'];
	}
	if (!window.requestAnimationFrame) {
		window.requestAnimationFrame = function(callback, element) {
			var currTime = new Date().getTime();
			var timeToCall = Math.max(0, 16 - (currTime - lastTime));
			var id = window.setTimeout(function() { callback(currTime + timeToCall); }, timeToCall);
			lastTime = currTime + timeToCall;
			return id;
		};
	}
	if (!window.cancelAnimationFrame) {
		window.cancelAnimationFrame = function(id) {
			clearTimeout(id);
		};
	}

	function formatNumber(num) {
		var neg = (num < 0),
			x, x1, x2, x3, i, len;
		num = Math.abs(num).toFixed(self.decimals);
		num += '';
		x = num.split('.');
		x1 = x[0];
		x2 = x.length > 1 ? self.options.decimal + x[1] : '';
		if (self.options.useGrouping) {
			x3 = '';
			for (i = 0, len = x1.length; i < len; ++i) {
				if (i !== 0 && ((i % 3) === 0)) {
					x3 = self.options.separator + x3;
				}
				x3 = x1[len - i - 1] + x3;
			}
			x1 = x3;
		}
		// optional numeral substitution
		if (self.options.numerals.length) {
			x1 = x1.replace(/[0-9]/g, function(w) {
				return self.options.numerals[+w];
			})
			x2 = x2.replace(/[0-9]/g, function(w) {
				return self.options.numerals[+w];
			})
		}
		return (neg ? '-' : '') + self.options.prefix + x1 + x2 + self.options.suffix;
	}
	// Robert Penner's easeOutExpo
	function easeOutExpo(t, b, c, d) {
		return c * (-Math.pow(2, -10 * t / d) + 1) * 1024 / 1023 + b;
	}
	function ensureNumber(n) {
		return (typeof n === 'number' && !isNaN(n));
	}

	self.initialize = function() { 
		if (self.initialized) return true;

		self.error = '';
		self.d = (typeof target === 'string') ? document.getElementById(target) : target;
		if (!self.d) { 
			self.error = '[CountUp] target is null or undefined'
			return false;
		}
		self.startVal = Number(startVal);
		self.endVal = Number(endVal);
		// error checks
		if (ensureNumber(self.startVal) && ensureNumber(self.endVal)) {
			self.decimals = Math.max(0, decimals || 0);
			self.dec = Math.pow(10, self.decimals);
			self.duration = Number(duration) * 1000 || 2000;
			self.countDown = (self.startVal > self.endVal);
			self.frameVal = self.startVal;
			self.initialized = true;
			return true;
		}
		else {
			self.error = '[CountUp] startVal ('+startVal+') or endVal ('+endVal+') is not a number';
			return false;
		}
	};

	// Print value to target
	self.printValue = function(value) {
		var result = self.options.formattingFn(value);

		if (self.d.tagName === 'INPUT') {
			this.d.value = result;
		}
		else if (self.d.tagName === 'text' || self.d.tagName === 'tspan') {
			this.d.textContent = result;
		}
		else {
			this.d.innerHTML = result;
		}
	};

	self.count = function(timestamp) {

		if (!self.startTime) { self.startTime = timestamp; }

		self.timestamp = timestamp;
		var progress = timestamp - self.startTime;
		self.remaining = self.duration - progress;

		// to ease or not to ease
		if (self.options.useEasing) {
			if (self.countDown) {
				self.frameVal = self.startVal - self.options.easingFn(progress, 0, self.startVal - self.endVal, self.duration);
			} else {
				self.frameVal = self.options.easingFn(progress, self.startVal, self.endVal - self.startVal, self.duration);
			}
		} else {
			if (self.countDown) {
				self.frameVal = self.startVal - ((self.startVal - self.endVal) * (progress / self.duration));
			} else {
				self.frameVal = self.startVal + (self.endVal - self.startVal) * (progress / self.duration);
			}
		}

		// don't go past endVal since progress can exceed duration in the last frame
		if (self.countDown) {
			self.frameVal = (self.frameVal < self.endVal) ? self.endVal : self.frameVal;
		} else {
			self.frameVal = (self.frameVal > self.endVal) ? self.endVal : self.frameVal;
		}

		// decimal
		self.frameVal = Math.round(self.frameVal*self.dec)/self.dec;

		// format and print value
		self.printValue(self.frameVal);

		// whether to continue
		if (progress < self.duration) {
			self.rAF = requestAnimationFrame(self.count);
		} else {
			if (self.callback) self.callback();
		}
	};
	// start your animation
	self.start = function(callback) {
		if (!self.initialize()) return;
		self.callback = callback;
		self.rAF = requestAnimationFrame(self.count);
	};
	// toggles pause/resume animation
	self.pauseResume = function() {
		if (!self.paused) {
			self.paused = true;
			cancelAnimationFrame(self.rAF);
		} else {
			self.paused = false;
			delete self.startTime;
			self.duration = self.remaining;
			self.startVal = self.frameVal;
			requestAnimationFrame(self.count);
		}
	};
	// reset to startVal so animation can be run again
	self.reset = function() {
		self.paused = false;
		delete self.startTime;
		self.initialized = false;
		if (self.initialize()) {
			cancelAnimationFrame(self.rAF);
			self.printValue(self.startVal);
		}
	};
	// pass a new endVal and start animation
	self.update = function (newEndVal) {
		if (!self.initialize()) return;
		newEndVal = Number(newEndVal);
		if (!ensureNumber(newEndVal)) {
			self.error = '[CountUp] update() - new endVal is not a number: '+newEndVal;
			return;
		}
		self.error = '';
		if (newEndVal === self.frameVal) return;
		cancelAnimationFrame(self.rAF);
		self.paused = false;
		delete self.startTime;
		self.startVal = self.frameVal;
		self.endVal = newEndVal;
		self.countDown = (self.startVal > self.endVal);
		self.rAF = requestAnimationFrame(self.count);
	};

	// format startVal on initialization
	if (self.initialize()) self.printValue(self.startVal);
};

async function runProgram()
{

	var objDate = new Date();
	var sec1 = objDate.getSeconds();
	var sec2 = sec1;
	var objDate2;
	while(true)
	{	
		objDate2 = new Date();
		sec2 = objDate2.getMilliseconds();
		await sleep(100); //sleep for 100 ms
		readTextFile("file:///home/pi/UCI-Digital-Waste-Bin/final/compost/result.json");
		console.log(result1);
		if(result2 != result1)
		{
			console.log("IT is different");
			result1 = result2;
			var result3 = 0.3968316 * result1;
			var r1 = document.getElementById("antpopup");
			var r2 = document.getElementById("SlideShow");
			//var s1 = document.getElementsByClassName('mySlides')[0];
			var pop = document.getElementsByClassName('popup')[0];
			var bot1 = document.getElementById("bot"); 
			var bot3 = document.getElementsByClassName('bot2')[0];
			//s1.classList.add('fadeo');
			await sleep(1000);
			r2.style.visibility = "hidden";
			//s1.classList.remove('fadeo');
			bot1.style.visibility = "visible";			
			r1.style.visibility = "visible";
			pop.classList.add('bounceup');
			bot3.classList.add('bounceup');
			await sleep(1000);
			pop.classList.remove('bounceup');
			bot3.classList.remove('bounceup');
			//document.getElementById("tbox").innerHTML = "The prodcut is this" + 10;
			var options = {
				useEasing: true, 
				useGrouping: true, 
				separator: '', 
				decimal: '.',
				suffix: ' ounces!'
			};
				var options2 = {
				useEasing: true, 
				useGrouping: true, 
				separator: '', 
				decimal: '.',
				prefix: 'You just helped avoid </br>',
				suffix: ' ounces'
			};
			var numAnim = new CountUp("tbox", 0.0, result1, 3, 2, options);
			if (!numAnim.error) {
				numAnim.start();
			} else {
				console.error(numAnim.error);
			}
			var numAnim2 = new CountUp("2box", 0.0, result3, 3, 2, options2);
			if (!numAnim2.error) {
				numAnim2.start();
			} else {
				console.error(numAnim2.error);
			}
			await sleep(8000);
			pop.classList.add('fadeo');
			bot3.classList.add('fadeo');
			await sleep(1000);
			pop.classList.remove('fadeo');
			bot3.classList.remove('fadeo');
			//s1.classList.add('fadeleft');
			bot1.style.visibility = "hidden";
			r1.style.visibility = "hidden" ;
			r2.style.visibility = "visible";

		}
	}
}

async function readTextFile(file)
{
	var rawFile = new XMLHttpRequest();
	rawFile.open("GET", file, false);
	rawFile.onreadystatechange = function ()
	{
		if(rawFile.readyState === 4)
		{
			if(rawFile.status === 200 || rawFile.status == 0)
			{
				var allText = rawFile.responseText;
				//alert(allText);
				parser = new DOMParser();
				xmlDoc = parser.parseFromString(allText,"text/xml");
				if(readFlag == 0)
				{
					console.log("Sets up result1")
					result1 = xmlDoc.getElementsByTagName("result")[0].childNodes[0].nodeValue;
					console.log(result1)
					readFlag = 1;
					result2 = result1;
				}
				else {result2 = xmlDoc.getElementsByTagName("result")[0].childNodes[0].nodeValue;}

				//console.log(result2*5);
			}
		}
	}
	rawFile.send(null);
}

async function carousel() {
	while(true)
	{
		var i;
		var x = document.getElementsByClassName("mySlides");
		for (i = 0; i < x.length; i++) {
			x[i].style.display = "none";  
		}
		myIndex++;
		if (myIndex > x.length) {myIndex = 1}    
		x[myIndex-1].style.display = "block";  
		await sleep(8000); //change image every 8 seconds
	}
	//setTimeout(carousel, 8000); // Change image every 2 seconds
}

//var readee; //GLOBAL File Reader object for demo purpose only

/**
 * Check for the various File API support.
 */
